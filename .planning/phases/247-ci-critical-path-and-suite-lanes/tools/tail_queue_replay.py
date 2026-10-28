#!/usr/bin/env python3
"""Phase 247 Plans 32 and 35 (D-27, D-29, D-31, D-32, D-33): tail-queue replay and PR preflight.

Standard library only; run as `python3 -I`. The repository root is resolved
from this file's own path. Every subcommand prints JSON on stdout and exits
non-zero when any check is violated. Not a CI gate.

Round 2 (D-32). The binding rules are the TQ-PREREG-2 block (P1-P10 plus the
D-32 disclosure) in 247-35-PLAN.md; this tool implements them and nothing
else. The runner's tail-queue size is per lane (`lane_tail_k`): LANE_K is
current 12, min 0, latest 0. K is read from the runner's own `tail queue: <q>
files lifted (K=<k>)` line and must equal LANE_K. A K=0 lane has no queue, so
its queue replay equals its static replay, and the current lane's assignment
must equal round 1's byte for byte. Gate component (a) covers GATE_LANES
(current) only; min and latest static replays are reported for information.
The preflight ratio bound is <= 1.15 on every lane (D-33); the claim-line and
pooled-overhead checks apply only to lanes with K > 0.

Round 1 (the all-lane K=12 runner, TQ-PREREG in 247-32-PLAN.md) stays
reproducible from git: this tool at b25c3c29 with the runner at cec42f3a.

  fetch --out <dir> [--print-pins]
      For every P2 run and lane, list the run's artifacts (read-only gh) and
      download partition-timings-<lane>-<run>. The zip must equal the API
      `digest` when the listing carries one; it must hold exactly
      partition-timings-1..4.tsv, which are parsed strictly and written to
      <dir>/<cohort>/<run>/<lane>/. Every TSV must equal its
      247-FROZEN-REPLAY.json pin when it has one (that JSON is verified
      against FROZEN_REPLAY_SHA256 first) and its PINNED_TSV_SHA256 entry.
      Missing or expired artifacts, and artifacts that fail validation, are
      listed as unavailable, never substituted. --print-pins prints the
      observed sha256 map instead of failing on keys absent from the pins.
  replay --root <dir> --overhead-ms <int> [--lane <lane>] [--run <id>]
      P1-P5. The assignment is the production runner's own, run in a
      temporary copy (runner and test tree) with MIX_BIN=false: once with the
      tail-queue seam unset (static sets plus tail-queue.tsv, queue replay)
      and once with CI_TEST_PARTITIONS_TAIL_K=0 (static calibration). Every
      partition time includes the run's boot (R3-IN-05).
  predict --replay-8000 <json> --replay-4000 <json> --fetch <json>
          --pre-registration-commit <sha>
      P6 and P10: the gate components, the gate, ci03_expectation and the
      CI-02 prediction, from the two full replays, the fetch record and
      247-B6-LOCAL-2.md. It also checks that the TQ-PREREG-2 block at the
      pre-registration commit equals the block in the current plan, and that
      round 1's 247-B6-PREDICTION.md is byte-unchanged. A gate FAIL is a
      computed outcome, so the exit status is still 0.
  preflight --run <id>
      P8 over attempt 1 of the landing PR's ci.yml run: GO or NO_GO. Exit 0
      whenever a verdict was computed; non-zero only on tool or API errors.
  --self-test
      Offline, table-driven checks of P3-P5, strict TSV parsing, digest
      rejection, the lift-line parser, TQ-PREREG-2 extraction, the
      current-only gate and the per-lane P8 log parser and verdict.
"""
import argparse
import hashlib
import io
import json
import os
import re
import shutil
import statistics
import subprocess
import sys
import tempfile
import zipfile
from decimal import Decimal, InvalidOperation
from pathlib import Path

PHASE_DIR = Path(__file__).resolve().parents[1]
ROOT = PHASE_DIR.parents[2]
TOOL_PATH = Path(__file__).resolve()
RUNNER_REL = "bin/ci-test-partitions"
COLOCATE_REL = "test/partition_colocate.txt"
PLAN_REL = ".planning/phases/247-ci-critical-path-and-suite-lanes/247-35-PLAN.md"
PREREG_MARKER = "TQ-PREREG-2"
PREDICTION_SCHEMA = "threadline.phase247-b6-prediction/2"
LOCAL_REL = "247-B6-LOCAL-2.md"
LOCAL_MARKER = "B6-LOCAL-2"
ROUND1_PREDICTION_REL = "247-B6-PREDICTION.md"
ROUND1_PREDICTION_SHA256 = "33fbbc3f4737e72929269e447a086ca99ef2444161a41d11137f5be804cefe09"
ROUND1_CURRENT_ASSIGNMENT_SHA256 = "542fbb543594050e2c4f0ca84774f7cc1dbae3d91e9f19deb601af3282fc45f0"
LANE_WEIGHTS = {
    "current": "test/partition_weights.txt",
    "min": "test/partition_weights_min.txt",
    "latest": "test/partition_weights_latest.txt",
}
LANES = ("current", "min", "latest")
REPO = "szTheory/threadline"
GH_BIN = "gh"
N_PARTITIONS = 4
# P1 (D-32): the runner's per-lane tail-queue size, `lane_tail_k`.
LANE_K = {"current": 12, "min": 0, "latest": 0}
# P6 (D-32): gate component (a) covers these lanes only.
GATE_LANES = ("current",)

# P2: the only runs this tool ever reads.
COHORTS = {
    "B3": (40433193088, 40434036118, 40434884357, 40436597341, 40437416932),
    "B4": (40449332597, 40450141708, 40450801580, 40451533079),
    "B5": (40692111621, 40693451272, 40694602284, 40695763585, 40696978392),
}
MEASUREMENT_JSON = {
    "B3": "247-B3-MEASUREMENT.json",
    "B4": "247-B4-INCOMPLETE.json",
    "B5": "247-B5-MEASUREMENT.json",
}

# P6, P8, P10 constants.
GATE_OVERHEAD_MS = 8000
INFO_OVERHEAD_MS = 4000
GATE_MAX_RATIO = 1.08
CI02_GATE_S = 510
CI02_LIMIT_S = 540
B5_MEDIAN_S = 457
PREFLIGHT_MAX_RATIO = Decimal("1.15")
PREFLIGHT_MAX_OVERHEAD_MS = 8000
LANE_JOB = {lane: f"Build and test ({lane})" for lane in LANES}
RUN_TESTS_GROUP = "##[group]Run mix verify.test_partitioned"

FROZEN_REPLAY_SHA256 = "5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1"

# (run, lane, partition) -> sha256 of partition-timings-<partition>.tsv, as
# observed by `fetch --print-pins` before any replay number existed.
PINNED_TSV_SHA256 = {
    (40433193088, "current", 1): "a4d227dd5000e1321164ee706b3ea0a252cea38ba37c31338df53b049c41dca8",
    (40433193088, "current", 2): "a5362f4817dfc713df8278a42285ef59f069b69019c789063753c765dde18f8e",
    (40433193088, "current", 3): "f86671d04dbea7b71b2fce0c1c6f5314316b9f6fca3439b9f779bd1d4efc445d",
    (40433193088, "current", 4): "1619671cd633bec3b6990acd678c02d9d5f72cad73ed021dfe3771d24d29ad50",
    (40433193088, "min", 1): "a76887eb5e37e485ec2d181e59d19a15afc141fd590056bce01f31726b0ff8c5",
    (40433193088, "min", 2): "d4597c8140e6caf968092efd1224942fa87d90df4812fede51dc6e795280f99b",
    (40433193088, "min", 3): "04709a65daf859c20380bb160f21cd11eff8af36c6ec88e3524ab846aa90d603",
    (40433193088, "min", 4): "aded70900a801df58b8a53913d6251a17108a92a5942176f5641e9aef58d8be3",
    (40433193088, "latest", 1): "dc4a00a6da6c145f13b77d9036c1334304ee792b3f1d8525ff6b8f5e37875bf4",
    (40433193088, "latest", 2): "e1d4a836726513c9bb17fe88c1b30858148e2b1208efd38e5c8cb1efd855b8e8",
    (40433193088, "latest", 3): "3fdfb5d55e4c06293a9ca76adb09b477491b147e34dc400178bc408f087615e3",
    (40433193088, "latest", 4): "58264691d53d2c5f963ff65949a840e9980a408a6d9e8e4343e4745a86b6d279",
    (40434036118, "current", 1): "eb8f60b89d33d57efa105acc0da064622ccfd7abcc1d00a94b076ef8611ccffe",
    (40434036118, "current", 2): "9c984219c942c5741f580418de2d82135199bd8afe9cf540205a278af2006538",
    (40434036118, "current", 3): "c0374ab1b9b45a2d6bdb533c1a00d1325322662a2d4bf0998911d96ed27bca60",
    (40434036118, "current", 4): "bb51e8778c27af649c95aeb040a75023e3bf3b8aaefb48b285317b1b3ef9c8cb",
    (40434036118, "min", 1): "51886731a37ee2021bd215dbb0dd46a4e6985e455b0bea7e3a595c166a0d9c3b",
    (40434036118, "min", 2): "8fa2e7934d74522c8b66677cacd7e1f8525467501471659bfbb8ebf829a8e503",
    (40434036118, "min", 3): "4b16ed4b2e59b71325950dd65ca8bb2398e1f1cf391608b21e2cb46025e289b5",
    (40434036118, "min", 4): "fe6cd48470a0b486ebe1a78bc3c6487caa3778d43b4cd646e23ac6616e2bbc91",
    (40434036118, "latest", 1): "661856454fec5f20f41e0f6a458ea0e602c94115b1957d1e931e185ce7e1f5db",
    (40434036118, "latest", 2): "762f1e7c5764db28f4a7f01932931ae0ce07d488913ca139f322495fa1a01815",
    (40434036118, "latest", 3): "927c360c100f60d290d661afed88cd044ff22327e1f9bef87cfc7a61775476d9",
    (40434036118, "latest", 4): "7047ff3419842c0bb2c59cdbd5f8a709eec43e84cd882c6adb48a48e2320ee06",
    (40434884357, "current", 1): "49eb0a638e479e0c9e16a0693dabc266614f7310751efc4f1b0c9555cf484fe2",
    (40434884357, "current", 2): "f79eb9ba7d269dbad09655e0944d5a9cba44252de5418d9785cfbc4f2d725255",
    (40434884357, "current", 3): "dcba0d970e0c18bc27802d8f157945f6fd7b743a0250cb423cbbb1b6ca26810b",
    (40434884357, "current", 4): "07d5dffd83766328ece33c78932eeb151fba95032596921f7222e2c10ce2ec7a",
    (40434884357, "min", 1): "86922db2a650584738ffdfa62748d12e66beed7a7ecc1e608cb93c07ca1150a1",
    (40434884357, "min", 2): "3244a31bb22d6befd7e24252b5d82906bb8d4a46af2d13cefe1b65008776f058",
    (40434884357, "min", 3): "08090d8d431f8fc146ad04c903930b0feec6078c735360ffaf7a2d5b0b2613cf",
    (40434884357, "min", 4): "1b6a172255aaf3f6dad6a39305754e4fb1e22c6a969775c9bcc646af71bb2e37",
    (40434884357, "latest", 1): "9166115eb16c8e3292271b4ff8a0d4f8f7cec15779ac040d7d17d2a5dc8fba6d",
    (40434884357, "latest", 2): "4c979ec8ff2fb9b4fe71154367d8d317c92ac277bb41d3291249d28a3f1e6640",
    (40434884357, "latest", 3): "8c3ca6abc7b4bf6531fc2bc75b61ae02a60c0e220a6f862eea480fee2209a569",
    (40434884357, "latest", 4): "2edf2c80efa7f8f7198d75607634b381c3f456cd087a9b370217ee15088e5094",
    (40436597341, "current", 1): "551055ed65ffb00ed859c08c9df332bd704373c75d48996afbe2104f2b5e2d0c",
    (40436597341, "current", 2): "3fddf83b56c35c6c0ee04d094231edc66c82c81b230e541143bdf2dcc915e749",
    (40436597341, "current", 3): "54aab5d1303bc55489533504fef5e7ca5eeb9b45f162c507dc730379f1cc1ce4",
    (40436597341, "current", 4): "644092424ba58452ec86fd9aaf61b5042e70fff7e46285467fd510292c8891fc",
    (40436597341, "min", 1): "fc0a93560f8f247f5c25b3abdd956965952b17e724b9306724fcd54cd1d58d5f",
    (40436597341, "min", 2): "c654563fb2891ee3a853e092e11347a98100b0bd9f17deef229f1fd4465957cb",
    (40436597341, "min", 3): "d13daf5cdd1a0da888b44d0e2dfa5ac3a426bd674192ecb97ee8654e867ab876",
    (40436597341, "min", 4): "2bea64c6996fa23ae8077d145d217639b154a58e38f489d4d01c1efdb8f25d84",
    (40436597341, "latest", 1): "822e14262c00315297e958d2924cb4229595cc3724993c37e4e51589d61e4a8e",
    (40436597341, "latest", 2): "f244b541cf53d7595d5f5e64c24075794ea9d08c5dd31123720f31ed00baa26d",
    (40436597341, "latest", 3): "348955975abaebd36f7c08a78605ea5d8cb4fedf730d00fbd773eae5daffba53",
    (40436597341, "latest", 4): "8f95d9d5cf52c243372b5c048b1aff6eb1c270b9cd2f8dc1ae7e10dc93adff9c",
    (40437416932, "current", 1): "731a91e6afa400a1370e91664727167349ca2b5f1b0ef205a787e5a6f2f0c45f",
    (40437416932, "current", 2): "10953f6d8df9613bb8a157f871213fc4958b3c0d5200c43c175f07a191aa2839",
    (40437416932, "current", 3): "bd7377b598441223a9a41b46ccf08639ecf09d47aef12d2cfca50f6b73d995b3",
    (40437416932, "current", 4): "7fdc2fd9c736377750325453b6101eaa2a927d28cc90239a7b36df7a8d8d871c",
    (40437416932, "min", 1): "2d4f45a93bf9eb776127cadc6441919b649b9a47542bce290dea526949772546",
    (40437416932, "min", 2): "9f5b651b9b608ea4d369e277a29f706fb1c9b27ec5bf6d2b602c28941d15e3c3",
    (40437416932, "min", 3): "7bc967b0b59d53deedc3737c88368a1e547a5dd341489c459566d8d75d6c59aa",
    (40437416932, "min", 4): "7fc0d73df39d2ac927762e1f3a64b63820fceed41d9b9cd17ebec16d79f28b40",
    (40437416932, "latest", 1): "325104edf27bf7166201a3c18de3bde76abb5937c6488f9d08d41b69dee44f36",
    (40437416932, "latest", 2): "1af468c8ff1de21f23b6f07c8c5bfaba004ac6434b1e412a3ebc464117e90a61",
    (40437416932, "latest", 3): "8cc212be1901cacb19727677fed4ff3645572b5d09473b4ffb218562d77aec56",
    (40437416932, "latest", 4): "b01ec262841e22a65ad40e74b1e4ac1b1f41126529bd95a0440b4d532d00e87a",
    (40449332597, "current", 1): "90d43c4786aa6d2535e446c27fd850939ff0d8d33cc62b24a352b92876ba71c2",
    (40449332597, "current", 2): "700cbb5dde3552a948ab657625ddafecc93d1631e24fe2305018afb87ba96a76",
    (40449332597, "current", 3): "5f03e0f72435cb0661572f7d511b8f8e6aa39269c2603dcaa031b718b0185a1b",
    (40449332597, "current", 4): "a3e2d643c71f824030277af9ae84fc55c7d76e4b0f804f6a0fee67240d99c990",
    (40449332597, "min", 1): "8f68d7e146ff567b86d67eb69051f8455ce8d070f0bd13ae498ecb2f6001054f",
    (40449332597, "min", 2): "ec634bf85a9f4f47222985fb3803a0231b41a590d6f470f448b1f9a1b90c7466",
    (40449332597, "min", 3): "2f85de00f0d218893531f3d290ee35f1262e4b8e473a464b7f046bc53b042724",
    (40449332597, "min", 4): "f38a93d7ca1c2c6674edc8a52bf4b3199efd3a1ab5c2411149e89e57c4a42961",
    (40449332597, "latest", 1): "1f7f2595baca96534a518a1a8fc546e44a5ff54d23c1c29a0eae953aa06032a7",
    (40449332597, "latest", 2): "f88b0fccc6104d7b4045424ac19cec2cc28b562af3ba531bb3cdb7df3c047909",
    (40449332597, "latest", 3): "5fe3e5ea66ea8fb2bf4d059de8fc8988e377d5b03fd4ba0b1ab6d8a9da921640",
    (40449332597, "latest", 4): "07e6c5486b6011dea22065d05dc5501c46f8693e326b6076a7b4fc6299abc6ae",
    (40450141708, "current", 1): "d2300948d7b0ae2a2c9df2db261a4d80225dbaed34aea572eb468b9147c8ff54",
    (40450141708, "current", 2): "8bc4451ab6ff046ec9a8ba5abb014e185b9a8de717a809f4c77c741f98554830",
    (40450141708, "current", 3): "6c0afa23b12efa80637ca587fe64858111a60455e7ed30abe64c1818824da795",
    (40450141708, "current", 4): "5b88d3bb5b2b04368989ccf6d1974f7c0af7b736534ff72ea0be85346342494f",
    (40450141708, "min", 1): "c35e333ad88d34993d272b9696e7b52a393d52ab4809ee4946e241d60f744246",
    (40450141708, "min", 2): "63246d80ec06ef6316aa570d85745712dd99f6ad731a87f8475cbf3a962128f1",
    (40450141708, "min", 3): "49daeb55cb2d7cbcf79f3bf6ff4abc56beae9b57cbb8429600ec6e32eae2e556",
    (40450141708, "min", 4): "311fbd2349cbae4d631d199bd40150f42262b61b19c9d9449b8eed5bbb61c07c",
    (40450141708, "latest", 1): "f063168142b362585509588de5eb7618e5419f0fe2b37b20e8aa8e5d6fb423d7",
    (40450141708, "latest", 2): "e8eceeb94c1eedee25b94c4ffcef150464fc1ef63681fc782f291ccca3ca4eb3",
    (40450141708, "latest", 3): "1ad7831b4b166f33dcbc0c292bd2953792353b58faf5be6a8b440c857735401d",
    (40450141708, "latest", 4): "03a0443a4835c5f982b7c8a9c5094f2e82fa05674c2ea48ea009bdbacf54523f",
    (40450801580, "current", 1): "cd7e6be6a94106e374efb0fb0889684679bf39c8c51f79b40ced0c61b61a960a",
    (40450801580, "current", 2): "422e62f523281c8b52649a0b0f0d3d8ba26939c52bb0ce362d544d7e92bd4df7",
    (40450801580, "current", 3): "552f3f4f8a7b48ac5e3c8b1e02d416e44bf5a352ce0df4ef4f0ec48950ea2881",
    (40450801580, "current", 4): "0490e13224658315ef7cd0ad7f810b63b82394d6af20b108383ace2ae7894b0c",
    (40450801580, "min", 1): "024eb134c78fc0ef3cc43a27c753297889b5840d1c1978f924829a71f0ad987e",
    (40450801580, "min", 2): "b372d03aeac068cc69aac0be2a4a394f1e91317b5f1c28575c7551bfb88246d9",
    (40450801580, "min", 3): "06e983c548acd22e4632f2f1fd426235eb5451fcc5ac8a4980598f77a62a5ff1",
    (40450801580, "min", 4): "6a2b1bdc21465ae3bbc1ac3e9ae01a59463c27a0daaa46da50756220cc4489ad",
    (40450801580, "latest", 1): "ad412b029fb29c1da379f43ee979827c44d21a8dbbcc110754b4c7c5196433cf",
    (40450801580, "latest", 2): "20f550cd1a8a981b5f1ab1beba46310a9e54d6c6557c8208b7f5b26f5281a618",
    (40450801580, "latest", 3): "708291eb84f01852cfaaaa1b87935660c03883a56563bfa7066bc91e50e59e75",
    (40450801580, "latest", 4): "3082718abc74b3452fbe5ee36a2222d88efe31531568e2e746b956ec3fa1d34f",
    (40451533079, "current", 1): "8cd0ab32c9c5e1802916fdbb22435feb26b52bcc1e043e9e5b8a06f4faae2b13",
    (40451533079, "current", 2): "1ca1078535f5b86fc6222e5808fe065d386c416bc6d1cd309e67565a4b279802",
    (40451533079, "current", 3): "09263aa23cd0d43fb7319b60413edc1ef43beecf15b849b236cf54babe3c2b41",
    (40451533079, "current", 4): "37dd942d322d61e275b48d839be8b638bc390723c37346c676b0c63b426a4de6",
    (40451533079, "min", 1): "e4a3bb798e0f8f625cfe2693b146b07ae4b1cbdb7d0c754a2a83e8a6ee764fc5",
    (40451533079, "min", 2): "4bbb0b9a2c84e3e1ec184272d873f08e19ac940f2f71bee8113f2ed5be3ff9f1",
    (40451533079, "min", 3): "783c3f620e8b39a3f991e63c415e21110b37227c0d619901f08a04da8fae61a5",
    (40451533079, "min", 4): "8d17634440826f8c3d15d92b8251f34a1b3b09f5ffde2a68426430d707c40465",
    (40451533079, "latest", 1): "5e6237d22cafbf69473c1c913158abf1200a4ca4b6c1417df267f783d0c87f21",
    (40451533079, "latest", 2): "de9a215eb07dda696f2a6752bd44c0b6224672094aa410ae566299b8a17ca6e9",
    (40451533079, "latest", 3): "214cc070bfbe5b595b3361aad576cdae0827017400b3289ac4b83886f71c0891",
    (40451533079, "latest", 4): "3a6e787355f5d782111ce069eebe359b656907885b0f3a1b5b5fdb1e39413352",
    (40692111621, "current", 1): "3fcf13ab7ad1d05563049a00ce0e77d5049fb715ac2afe2a5416f6ae81a2a223",
    (40692111621, "current", 2): "82a84f126b76764f99ccde6f15fd74f61dddef26f550bfbbbd4b5e82bf221fa3",
    (40692111621, "current", 3): "91046b412ffdb44e6a82ff4f7c4eb7b13b0d1c5f144b79cbdbf1f4375c22a2fc",
    (40692111621, "current", 4): "fb52fe75ea5ed44db3e6d550a3bc7ee0b1d5f37243be2aba41b0e3975e35b8e8",
    (40692111621, "min", 1): "1ee8885ddeb3a83e56e8a9e08ffc410291e05e8d8d8a55ffde5082314bb569e6",
    (40692111621, "min", 2): "7f4712ca40d09982f6d319291fa6fdcced8aaf2684f993eb3d680059842a6298",
    (40692111621, "min", 3): "f2ff0ebb8038c362e0328ab6f5e27ae80df6eeab2340a5ab1f14d7103a0e6903",
    (40692111621, "min", 4): "7254042c163871021789b36cd47ed5a24a1b8b1fde5469df4c745c9c2dccbb57",
    (40692111621, "latest", 1): "059b00c063c5b90a8c1b1d816d087f68b2b2a90ad450e3496bea28380637b41c",
    (40692111621, "latest", 2): "5d1b24e80a04873f95fcc30504fcded118b4fc96f43486812e0510466c7917cc",
    (40692111621, "latest", 3): "78da9556c2cb17bfe2e54631b1ba9716c2adc479898dc6cd71b0d1e2e6030681",
    (40692111621, "latest", 4): "a4426b9285ee86cac269453ffb57505d307daa0f51c7c9f0b63934b98582b96a",
    (40693451272, "current", 1): "7dc441a7c1539862f4f14cb6a565d1811532bbf07473798aa7068c232b246620",
    (40693451272, "current", 2): "801465c84845ff959f9242309735a33f5f6a62bb9e7e37faacc12fa63ec41fa2",
    (40693451272, "current", 3): "5c0e0cda2c32cd7de9956b7c3de127bccb7a4bf5d95150d7151d66cb90729e43",
    (40693451272, "current", 4): "f55549a2a40e38d15d3253a2273f82a1e75a4cdfdd353014e6b5850acc304a65",
    (40693451272, "min", 1): "3cb610929fc5e34446802ba7f4b3f7b0277137ea4b0da5039c08ecd20946d7dc",
    (40693451272, "min", 2): "8f2715cb6fa0659ce3a97ae69ee08e26774c77d27ec0b87a110f1de5a142bd13",
    (40693451272, "min", 3): "01b6f0c6e7f4091a39b5266875a6397a156de7f493f0ad54a684374990dfe07d",
    (40693451272, "min", 4): "c0dda62acea1a1870f61623fec9d983b62a602ef2658b243f9d25f8b3f47409e",
    (40693451272, "latest", 1): "68701ca29e49132c9a28e9f0eaf595c9080779e4297906847667a37d1dedd1cf",
    (40693451272, "latest", 2): "17696e607efb712460b3e54ea11237854d4ca46d6f2fa77cd5d10c6e111faa3d",
    (40693451272, "latest", 3): "34d62efb4bf200a45810b670436708574c67d694883595ab1a09b5bfe9150988",
    (40693451272, "latest", 4): "fe5f5b091e42f6aa886778ea757097d9883c65366ec2d38b01c7594ec2275a66",
    (40694602284, "current", 1): "049d2b96f1eeb3a3179689c550147f2c8d18a0fb400a96eb2e3456063877718c",
    (40694602284, "current", 2): "0952c1701a02d2a26e2384af1415ed15d8055dc98f77e1c68431b7283e8018a4",
    (40694602284, "current", 3): "073a6b0353d1906610afbd832a49df184dad3744285c910d0ab8ded62e795bf7",
    (40694602284, "current", 4): "bb1f2c7af1f5982fe6256e0849ce11b0c27fd2010e581833d840be70f267bea1",
    (40694602284, "min", 1): "db0c2ffee7a060380745e7959ce0fd7de6f794c05e63ea9715008a10eb401af6",
    (40694602284, "min", 2): "3a0d9df6a78ebc0556646fb4751e646be80d5e1fa17489f8bf208f97050d8a91",
    (40694602284, "min", 3): "eef5b1cf2b6d934fb907251de508890538e1c255054128b519aa6272e84fb54c",
    (40694602284, "min", 4): "ee88cf22e416aee6e497a30eb1c10c138fddff71e3190fa44fee244ebfe95b56",
    (40694602284, "latest", 1): "5c7de2024df1ae775871acc7bf4d3a617763cfb240fb6d25669bbc64fe3d89e1",
    (40694602284, "latest", 2): "5ac6a5b8716f027e9aa9f70b8739b8f399693741fd4aade253792a720d9a80ac",
    (40694602284, "latest", 3): "bb87b5317256d9e939bcb162b0c173300a9dc9e208263b7e051e591da348cde2",
    (40694602284, "latest", 4): "13e4b4c70979198a28ad9dd96f8cf48e1d8e47ebe180049013cf7e2a563a7e1f",
    (40695763585, "current", 1): "01a3e79c1877468be636e4eef7cc8391f2613b8c07cb3d559d4029d213bd1ca2",
    (40695763585, "current", 2): "9805b347d333e3de05e6527691281ba78fc1a825ed1c30c834cc3844544b45de",
    (40695763585, "current", 3): "76eeecc61ee7088c3bfbb04cf33148a014629beb52d623053260e6401806b070",
    (40695763585, "current", 4): "4c5686033fb40ce16d1e460a8c05724f0d70d1f39b7474caaed0ce489b698dc5",
    (40695763585, "min", 1): "81305bb1522bde47209d096c9af238b0b1b9908e1d1e6bae063719ab583b1d45",
    (40695763585, "min", 2): "fabe6e8bbc621ddbd8009963e681f7edc5c786db9a258f4fd3b7feaa1b7fd8fe",
    (40695763585, "min", 3): "470a60afd36cc034dfd3b4e850e4ad5a6be4169b602702b94d1220c754020f15",
    (40695763585, "min", 4): "2fd2d6cbca446bca2885580087856610b6278d08e4ee14cd07f641fc2236a1c9",
    (40695763585, "latest", 1): "fc6b38b610e879a1c9842777179a7e164cb2bf43e86e6abad9bf9ee36b8500a7",
    (40695763585, "latest", 2): "70c5eb1d5f11e03df0732649d921d6e33b56c3b73076842da3c463a85298c75f",
    (40695763585, "latest", 3): "22491d0970d2347c8e4c8dbf32e253191fc62444801edf09790ceeeed92e91d0",
    (40695763585, "latest", 4): "7da5aeac208df64cb8ef561efe447d849385b29b9c59c8c6f11ff0b1d3c4694d",
    (40696978392, "current", 1): "2197b1082138f3a2bbd445660cea8965887b8ca3b8b78d581b488fc31d90d9a3",
    (40696978392, "current", 2): "a07a2b1243b65da66a094a2e6a70fc170cd54fdc62da00441fcf13b201de250f",
    (40696978392, "current", 3): "4de51f55735ac845f9e83c6e53d9e04f1d8e8ee0c14eb586bd750ca3d00d354d",
    (40696978392, "current", 4): "690dc7e3f7278ab8b2712e21b5f0815225de76f300287f74c0e44d3e77dcc956",
    (40696978392, "min", 1): "3ff0fa532846bf7094efdc6a5bd00f65694c7ab26ce0ac4516d180936f5c8a6c",
    (40696978392, "min", 2): "4e18c5f096fa23d0afc1faaf35f534bf926567c2d71bc8b8c63435fec0a0ae3a",
    (40696978392, "min", 3): "c3b1770d0177c53f17c15616bf816601d851509c6cdae5357f2835070259845a",
    (40696978392, "min", 4): "51898a95575ddf73e2d711417fae5f37f2076417fbb6019ed552483add1c26fd",
    (40696978392, "latest", 1): "cfb5ce33035ae6f6542ab63eb7b77ba8bf542fdd28967933221ccea2d777bdb5",
    (40696978392, "latest", 2): "e7e34b1374fae583b209afb82061e8f2573bfd795df90c0f0f02919e0a0b4bdc",
    (40696978392, "latest", 3): "5d673f789de51b11db6e234d6af01bbec2dc0f3c6c33076a8cda59b9f3f8918d",
    (40696978392, "latest", 4): "62f97d2cd219d5416c0abee325acfa088cbb5187cdeb43b19f5149a21b0e5a39",
}

SPACE = r"[ \t\r\f\v]"
ASYNC_RX = re.compile(r"^" + SPACE + r"*use [A-Za-z0-9_.]+,.*async:" + SPACE + r"*true", re.M)
HEADER_RX = re.compile(
    r"# threadline\.partition-timings/1 partition=([1-4]) lane=([a-z][a-z0-9-]*) "
    r"boot_ms=([0-9]+) wall_ms=([0-9]+)")
ROW_PATH_RX = re.compile(r"test/[^\s]+_test\.exs")
DIGITS_RX = re.compile(r"[0-9]+")
TSV_NAMES = [f"partition-timings-{p}.tsv" for p in range(1, N_PARTITIONS + 1)]
MAX_TSV_BYTES = 1 << 20

TS_RX = re.compile(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]+)?Z ?")
ANSI_RX = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
RATIO_ROW_RX = re.compile(r"^\|[ \t]*max/min[ \t]*\|[^|]*\|[ \t]*([^|]*?)[ \t]*\|")
RATIO_VALUE_RX = re.compile(r"[0-9]+(?:\.[0-9]+)?")
LIFT_LINE_RX = re.compile(
    r"^ci-test-partitions: tail queue: ([0-9]+) files lifted \(K=([0-9]+)\), weight ([0-9]+) ms$", re.M)
QUEUE_LINE_PREFIX = "ci-test-partitions: tail queue K="
QUEUE_LINE_RX = re.compile(
    r"ci-test-partitions: tail queue K=([0-9]+) queued=([0-9]+) claimed=([0-9]+) "
    r"overhead_mean_ms=([0-9]+|n/a)")
CLAIM_LINE_PREFIX = "ci-test-partitions: claim "
CLAIM_LINE_RX = re.compile(
    r"ci-test-partitions: claim partition=([1-9][0-9]*) seq=([0-9]+) file=(\S+) "
    r"start_ms=([0-9]+) end_ms=([0-9]+) exit=([0-9]+) file_wall_ms=([0-9]+) overhead_ms=(-?[0-9]+)")


class CheckError(Exception):
    pass


class ApiError(Exception):
    pass


def require(cond, message):
    if not cond:
        raise CheckError(message)


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def sha256_file(path):
    return sha256_bytes(Path(path).read_bytes())


def digits(value, label):
    require(isinstance(value, (int, str)) and DIGITS_RX.fullmatch(str(value)) is not None,
            f"{label} must be decimal digits, got {value!r}")
    return str(value)


def cohort_of(run):
    for cohort, runs in COHORTS.items():
        if int(run) in runs:
            return cohort
    raise CheckError(f"run {run} is not a P2 run")


# --- GitHub boundary (read-only, closed over symbolic operations) -----------------

_escape_flag = None


def escape_flag():
    """gh 2.101+ refuses to print escape sequences without --allow-escape-sequences;
    older gh rejects the flag. Detect once from the local `gh api --help`."""
    global _escape_flag
    if _escape_flag is None:
        proc = subprocess.run([GH_BIN, "api", "--help"], capture_output=True, text=True, timeout=60)
        _escape_flag = "--allow-escape-sequences" in (proc.stdout + proc.stderr)
    return _escape_flag


def gh_read(operation, ident):
    ident = digits(ident, f"{operation} id")
    base = f"repos/{REPO}/actions"
    if operation == "artifacts":
        args = ["api", f"{base}/runs/{ident}/artifacts?per_page=100"]
    elif operation == "artifact-zip":
        args = ["api", f"{base}/artifacts/{ident}/zip"]
    elif operation == "run-attempt-1":
        args = ["api", f"{base}/runs/{ident}/attempts/1"]
    elif operation == "attempt-1-jobs":
        args = ["api", f"{base}/runs/{ident}/attempts/1/jobs?per_page=100"]
    elif operation == "job-log":
        args = ["api", f"{base}/jobs/{ident}/logs"] + (["--allow-escape-sequences"] if escape_flag() else [])
    else:
        raise CheckError(f"rejected unknown read operation: {operation}")
    try:
        proc = subprocess.run([GH_BIN] + args, capture_output=True, timeout=300)
    except (OSError, subprocess.SubprocessError) as exc:
        raise ApiError(f"gh {operation} {ident}: {exc}")
    if proc.returncode != 0:
        raise ApiError(f"gh {operation} {ident} failed: {proc.stderr.decode(errors='replace').strip()[:400]}")
    return proc.stdout


def gh_json(operation, ident):
    try:
        return json.loads(gh_read(operation, ident))
    except ValueError as exc:
        raise ApiError(f"gh {operation} {ident}: invalid JSON: {exc}")


# --- strict inputs ------------------------------------------------------------------

def verify_digest(data, digest):
    """The API listing's `digest` is `sha256:<64 hex>` of the artifact zip."""
    require(isinstance(digest, str) and re.fullmatch(r"sha256:[0-9a-f]{64}", digest) is not None,
            f"malformed artifact digest {digest!r}")
    actual = "sha256:" + sha256_bytes(data)
    require(actual == digest, f"artifact zip {actual} != listed digest {digest}")
    return actual


def unpack_artifact(data):
    """Exactly partition-timings-1..4.tsv, no directories, no other members."""
    try:
        zf = zipfile.ZipFile(io.BytesIO(data))
    except zipfile.BadZipFile as exc:
        raise CheckError(f"not a zip: {exc}")
    infos = zf.infolist()
    names = sorted(i.filename for i in infos)
    require(names == TSV_NAMES, f"artifact members {names} != {TSV_NAMES}")
    out = {}
    for info in infos:
        require(info.file_size <= MAX_TSV_BYTES, f"{info.filename} is larger than {MAX_TSV_BYTES} bytes")
        out[int(info.filename.split("-")[-1].split(".")[0])] = zf.read(info)
    return out


def parse_tsv_strict(data, lane, partition):
    """ASCII only, `\\n`-only records ending in `\\n`, a strict header, three-field
    rows of ASCII digits, and no duplicate file (R3-IN-01)."""
    require(isinstance(data, bytes), "TSV input must be bytes")
    try:
        text = data.decode("ascii")
    except UnicodeDecodeError:
        raise CheckError("non-ASCII byte in timing TSV")
    require("\r" not in text, "CR in timing TSV (records must be \\n-only)")
    require(text.endswith("\n"), "timing TSV does not end in \\n")
    lines = text[:-1].split("\n")
    header = HEADER_RX.fullmatch(lines[0])
    require(header is not None, f"invalid timing header: {lines[0]!r}")
    require(header.group(2) == lane, f"wrong-lane timing header: lane={header.group(2)}, expected {lane}")
    require(int(header.group(1)) == partition, f"partition header {header.group(1)} != {partition}")
    rows = {}
    for line in lines[1:]:
        bits = line.split("\t")
        require(len(bits) == 3 and ROW_PATH_RX.fullmatch(bits[0]) is not None
                and DIGITS_RX.fullmatch(bits[1]) is not None and DIGITS_RX.fullmatch(bits[2]) is not None,
                f"malformed timing row: {line!r}")
        require(bits[0] not in rows, f"duplicate timing row: {bits[0]}")
        rows[bits[0]] = int(bits[1])
    return {"partition": partition, "boot_ms": int(header.group(3)), "wall_ms": int(header.group(4)),
            "rows": rows}


def merge_observed(parsed_by_partition):
    observed = {}
    for p in sorted(parsed_by_partition):
        for f, wall in parsed_by_partition[p]["rows"].items():
            require(f not in observed, f"file observed twice in one run: {f}")
            observed[f] = wall
    return observed


def frozen_expectations(phase_dir=PHASE_DIR):
    raw = (phase_dir / "247-FROZEN-REPLAY.json").read_bytes()
    require(sha256_bytes(raw) == FROZEN_REPLAY_SHA256, "247-FROZEN-REPLAY.json differs from its pinned sha256")
    expected = {}
    for item in json.loads(raw)["manifest"]["artifact_hashes"]:
        key = (int(item["run_id"]), item["lane"], int(item["partition"]))
        require(key not in expected, f"duplicate pinned artifact identity {key}")
        expected[key] = item["artifact_sha256"]
    return expected


def measured_ratios(phase_dir=PHASE_DIR):
    """(run, lane) -> measured ratio; ratios.<lane>[i] belongs to runs[i].id."""
    out = {}
    for cohort, name in MEASUREMENT_JSON.items():
        d = json.loads((phase_dir / name).read_text())
        ids = [int(r["id"]) for r in d["runs"]]
        require(ids == list(COHORTS[cohort]), f"{name}: runs {ids} != P2 {list(COHORTS[cohort])}")
        for lane in LANES:
            vals = d["ratios"][lane]
            require(len(vals) == len(ids), f"{name}: {lane} ratios do not align with runs")
            for rid, v in zip(ids, vals):
                out[(rid, lane)] = v
    return out


# --- P3-P5 ------------------------------------------------------------------------

def bin_cost(sync_sum, async_sum, longest_async, factor_permille):
    """S + max(D, L), D = floor(A * factor / 1000), at least 1 when A > 0."""
    discounted = async_sum * factor_permille // 1000
    if async_sum > 0 and discounted < 1:
        discounted = 1
    return sync_sum + max(discounted, longest_async)


def effective_weight(raw, is_async, factor_permille):
    eff = raw * factor_permille // 1000 if is_async else raw
    return max(eff, 1)


def boot_lower_middle(boots):
    require(len(boots) == N_PARTITIONS, f"expected {N_PARTITIONS} boot_ms values, got {len(boots)}")
    return sorted(boots)[N_PARTITIONS // 2 - 1]


def amount(f, observed, raw):
    return observed[f] if f in observed else raw[f]


def static_times(sets, observed, raw, async_map, factor, boot):
    """P3: T_p = boot + S + max(D, L) over p's static files."""
    times, counts = {}, {}
    for p in range(1, N_PARTITIONS + 1):
        s = a = longest = 0
        for f in sets[p]:
            w = amount(f, observed, raw)
            if async_map[f]:
                a += w
                longest = max(longest, w)
            else:
                s += w
        times[p] = boot + bin_cost(s, a, longest, factor)
        counts[p] = len(sets[p])
    return times, counts


def claim_queue(times, counts, queue_files, observed, raw, overhead_ms):
    """P4: each claim, in queue order, goes to the smallest current T (ties to the
    lowest partition) and adds its wall_ms (or raw weight) plus overhead_ms."""
    times, counts, claims = dict(times), dict(counts), {}
    for f in queue_files:
        p = min(sorted(times), key=lambda q: (times[q], q))
        times[p] += amount(f, observed, raw) + overhead_ms
        counts[p] += 1
        claims[f] = p
    return times, counts, claims


def ratio_over(times, counts):
    """P5: max/min over all partitions; a partition with no file and no claim fails."""
    require(sorted(times) == list(range(1, N_PARTITIONS + 1)), f"partitions {sorted(times)} != 1..{N_PARTITIONS}")
    empty = sorted(p for p in times if counts[p] <= 0)
    require(not empty, f"partitions with no static file and no claim: {empty}")
    require(min(times.values()) > 0, f"a partition has a non-positive time: {times}")
    return max(times.values()) / min(times.values())


# --- the runner, in a temporary copy -----------------------------------------------

def read_weights(path):
    """Runner semantics: `<ms> <file>` lines, comments and blanks skipped, duplicates summed."""
    weights = {}
    for line in Path(path).read_text().splitlines():
        if re.match(r"^[ \t]*#", line) or re.match(r"^[ \t]*$", line):
            continue
        bits = re.split(r"[ \t]+", line)
        if len(bits) >= 2 and re.fullmatch(r"[0-9]+", bits[0]):
            weights[bits[1]] = weights.get(bits[1], 0) + int(bits[0])
    return weights


def raw_weight_map(weights, files):
    """Median fallback over the enumerated files that carry a weight (assign_files)."""
    vals = sorted(weights[f] for f in files if f in weights)
    m = len(vals)
    if m == 0:
        med = 1000
    elif m % 2 == 1:
        med = vals[(m + 1) // 2 - 1]
    else:
        med = (vals[m // 2 - 1] + vals[m // 2]) // 2
    return {f: weights.get(f, med) for f in files}


def parse_lift_line(stdout, queued):
    """P1 (D-32): K is the K on the runner's single `tail queue: <q> files lifted
    (K=<k>), weight <w> ms` stdout line, and <q> must equal the queue length."""
    m = LIFT_LINE_RX.findall(stdout)
    require(len(m) == 1, f"expected one `tail queue: … files lifted (K=…)` line, found {len(m)}")
    lifted, k, _weight = (int(x) for x in m[0])
    require(lifted == queued, f"lift line says {lifted} files lifted, tail-queue.tsv holds {queued}")
    return k


def runner_constant(root, name):
    m = re.search(r"^" + name + r"=([0-9]+)$", (Path(root) / RUNNER_REL).read_text(), re.M)
    require(m, f"{name} not found in the runner")
    return int(m.group(1))


def stage_copy(root=ROOT):
    """A temporary copy of the runner and the whole test tree (with the colocation file)."""
    root = Path(root)
    tmp = Path(tempfile.mkdtemp(prefix="tail-queue-replay-copy-"))
    try:
        (tmp / "bin").mkdir()
        shutil.copy2(root / RUNNER_REL, tmp / RUNNER_REL)
        for src in (root / "test").rglob("*"):
            if src.is_file():
                dst = tmp / src.relative_to(root)
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
        return tmp
    except BaseException:
        shutil.rmtree(tmp, ignore_errors=True)
        raise


def run_assignment(lane, tail_k=None, root=ROOT):
    """P1: the runner's own static sets and tail-queue.tsv, from a temporary copy
    stopped at the serial compile. tail_k=None leaves the seam unset (the lane's
    own lane_tail_k); a number sets CI_TEST_PARTITIONS_TAIL_K. K is read from the
    runner's lift line, never from its source."""
    copy = stage_copy(root)
    try:
        log_dir = copy / "tail-queue-replay-logs"
        env = {k: v for k, v in os.environ.items()
               if not (k.startswith("CI_TEST_PARTITIONS_") or k.startswith("THREADLINE_")
                       or k == "GITHUB_STEP_SUMMARY")}
        env.update({"MIX_BIN": "false", "CI_TEST_PARTITIONS_LOG_DIR": str(log_dir), "THREADLINE_CI_LANE": lane})
        if lane in ("min", "latest"):
            env["THREADLINE_TEST_SCOPE"] = "toolchain"
        if tail_k is not None:
            env["CI_TEST_PARTITIONS_TAIL_K"] = str(tail_k)
        proc = subprocess.run([str(copy / RUNNER_REL), str(N_PARTITIONS)], cwd=copy, env=env,
                              capture_output=True, text=True, timeout=300)
        require(proc.returncode != 0 and "serial compile failed" in proc.stderr,
                f"runner did not stop at the serial compile (exit {proc.returncode}): {proc.stderr[-400:]}")
        enumerated = (log_dir / "enumerated.txt").read_text().splitlines()
        require(enumerated and len(set(enumerated)) == len(enumerated), "enumerated.txt is empty or repeats a file")
        eff, assigned = {}, {}
        for line in (log_dir / "assignment.tsv").read_text().splitlines():
            p, f, w = line.split("\t")
            require(f not in eff, f"assignment repeats {f}")
            eff[f], assigned[f] = int(w), int(p)
        sets_bytes, sets = b"", {}
        for p in range(1, N_PARTITIONS + 1):
            raw_bytes = (log_dir / f"partition-{p}.files").read_bytes()
            sets_bytes += f"partition-{p}.files\n".encode() + raw_bytes
            sets[p] = [x for x in raw_bytes.decode().split("\n") if x]
        queue_bytes = (log_dir / "tail-queue.tsv").read_bytes()
        queue = []
        for n, line in enumerate(x for x in queue_bytes.decode().split("\n") if x):
            seq, f, w = line.split("\t")
            require(int(seq) == n + 1, f"tail-queue.tsv seq {seq} out of order")
            require(int(w) == eff[f], f"tail-queue.tsv weight for {f} differs from assignment.tsv")
            queue.append(f)
        placed = [f for p in sets for f in sets[p]] + queue
        require(sorted(placed) == sorted(enumerated) and len(placed) == len(set(placed)),
                "static sets plus queue do not cover the enumerated files exactly once")
        for p in sets:
            require(all(assigned[f] == p for f in sets[p]), f"partition-{p}.files leaves its greedy set")
        factor = runner_constant(copy, "ASYNC_FACTOR_PERMILLE")
        raw = raw_weight_map(read_weights(copy / LANE_WEIGHTS[lane]), enumerated)
        async_map = {f: bool(ASYNC_RX.search((copy / f).read_text(errors="replace"))) for f in enumerated}
        for f in enumerated:
            require(effective_weight(raw[f], async_map[f], factor) == eff[f],
                    f"effective weight mismatch for {f}: runner {eff[f]}")
        require(not any(async_map[f] for f in queue), "the runner queued an async file")
        return {"enumerated": enumerated, "sets": sets, "queue": queue, "raw": raw, "async": async_map,
                "factor": factor, "k": parse_lift_line(proc.stdout, len(queue)),
                "runner_sha256": sha256_file(copy / RUNNER_REL),
                "assignment_sha256": sha256_bytes(sets_bytes + b"tail-queue.tsv\n" + queue_bytes)}
    finally:
        shutil.rmtree(copy, ignore_errors=True)


# --- fetch --------------------------------------------------------------------------

def cmd_fetch(args):
    out = Path(args.out).resolve()
    # Plain files (a shell redirect of this command's own output) may exist; no directory may.
    require(not out.exists() or not any(x.is_dir() for x in out.iterdir()),
            f"{out} already holds directories; use an empty directory")
    out.mkdir(parents=True, exist_ok=True)
    frozen = frozen_expectations()
    counts = {"available": 0, "digest_verified": 0, "frozen_verified": 0, "pinned_verified": 0}
    unavailable, observed_pins, tsv_sha = [], {}, {}
    for cohort, runs in COHORTS.items():
        for run in runs:
            listing = gh_json("artifacts", run)
            arts = listing.get("artifacts", [])
            require(len(arts) == listing.get("total_count"), f"run {run}: artifact listing is paginated")
            for lane in LANES:
                name = f"partition-timings-{lane}-{run}"
                matches = [a for a in arts if a.get("name") == name]
                miss = None
                if not matches:
                    miss = "artifact missing"
                elif len(matches) > 1:
                    miss = "more than one artifact with this name"
                elif matches[0].get("expired") is not False:
                    miss = "artifact expired"
                if miss:
                    unavailable.append({"cohort": cohort, "run": run, "lane": lane, "reason": miss})
                    continue
                art = matches[0]
                data = gh_read("artifact-zip", digits(art["id"], "artifact id"))
                if art.get("digest") is not None:
                    verify_digest(data, art["digest"])
                    counts["digest_verified"] += 1
                try:
                    members = unpack_artifact(data)
                    parsed = {p: parse_tsv_strict(members[p], lane, p) for p in sorted(members)}
                    merge_observed(parsed)
                except CheckError as exc:
                    unavailable.append({"cohort": cohort, "run": run, "lane": lane,
                                        "reason": f"validation failed: {exc}"})
                    continue
                dest = out / cohort / str(run) / lane
                dest.mkdir(parents=True)
                for p in sorted(members):
                    key = (run, lane, p)
                    h = sha256_bytes(members[p])
                    if key in frozen:
                        require(h == frozen[key], f"{key}: sha256 {h} != 247-FROZEN-REPLAY.json pin {frozen[key]}")
                        counts["frozen_verified"] += 1
                    if key in PINNED_TSV_SHA256:
                        require(h == PINNED_TSV_SHA256[key], f"{key}: sha256 {h} != PINNED_TSV_SHA256 {PINNED_TSV_SHA256[key]}")
                        counts["pinned_verified"] += 1
                    else:
                        require(args.print_pins, f"{key}: no PINNED_TSV_SHA256 entry")
                    observed_pins[f"{run}/{lane}/{p}"] = h
                    tsv_sha.setdefault(str(run), {}).setdefault(lane, {})[str(p)] = h
                    (dest / TSV_NAMES[p - 1]).write_bytes(members[p])
                    counts["available"] += 1
    result = dict(counts)
    result.update({"unavailable": unavailable, "frozen_replay_sha256": FROZEN_REPLAY_SHA256,
                   "cohorts": {c: list(r) for c, r in COHORTS.items()}, "tsv_sha256": tsv_sha})
    if args.print_pins:
        result["pins"] = observed_pins
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


# --- replay -------------------------------------------------------------------------

def load_run_dir(run_dir, run, lane):
    names = sorted(x.name for x in run_dir.iterdir())
    require(names == TSV_NAMES, f"{run}/{lane}: unexpected contents {names}")
    parsed = {}
    for p in range(1, N_PARTITIONS + 1):
        data = (run_dir / TSV_NAMES[p - 1]).read_bytes()
        key = (run, lane, p)
        require(key in PINNED_TSV_SHA256, f"{key}: no PINNED_TSV_SHA256 entry")
        require(sha256_bytes(data) == PINNED_TSV_SHA256[key], f"{key}: TSV differs from its pin")
        parsed[p] = parse_tsv_strict(data, lane, p)
    return {"observed": merge_observed(parsed), "boot_ms": [parsed[p]["boot_ms"] for p in sorted(parsed)]}


def discover(root):
    """root/<cohort>/<run>/<lane>/ for P2 runs only; top-level files are ignored."""
    found = {}
    for entry in sorted(Path(root).iterdir()):
        if not entry.is_dir():
            continue
        require(entry.name in COHORTS, f"unexpected directory under the replay root: {entry.name}")
        for run_dir in sorted(entry.iterdir()):
            require(run_dir.is_dir() and run_dir.name.isascii() and run_dir.name.isdigit()
                    and int(run_dir.name) in COHORTS[entry.name],
                    f"{entry.name}/{run_dir.name} is not a P2 run of {entry.name}")
            for lane_dir in sorted(run_dir.iterdir()):
                require(lane_dir.is_dir() and lane_dir.name in LANES, f"unexpected {entry.name}/{run_dir.name}/{lane_dir.name}")
                found[(int(run_dir.name), lane_dir.name)] = lane_dir
    return found


def replay_lane(lane, found, overhead_ms, measured, only_run=None, root=ROOT):
    qa = run_assignment(lane, None, root)
    sa = run_assignment(lane, 0, root)
    require(qa["k"] == LANE_K[lane], f"{lane}: runner lift line K={qa['k']}, pre-registered {LANE_K[lane]}")
    require(sa["k"] == 0, f"{lane}: the static calibration (TAIL_K=0) printed K={sa['k']}")
    require(qa["enumerated"] == sa["enumerated"] and qa["raw"] == sa["raw"], "the two assignments see different inventories")
    require(sa["queue"] == [], "the static calibration (TAIL_K=0) queued files")
    require(len(qa["queue"]) <= qa["k"], "the runner queued more than K files")
    if LANE_K[lane] == 0:
        # P1 second input check: a K=0 lane queues nothing, so its seam-unset
        # assignment is its TAIL_K=0 assignment.
        require(qa["queue"] == [], f"{lane}: K=0 but the runner queued files")
        require(qa["assignment_sha256"] == sa["assignment_sha256"],
                f"{lane}: K=0 seam-unset assignment differs from the TAIL_K=0 assignment")
    if lane == "current":
        # P1 first input check: the current lane replays round 1's queue exactly.
        require(qa["assignment_sha256"] == ROUND1_CURRENT_ASSIGNMENT_SHA256,
                f"current-lane assignment differs from round 1: {qa['assignment_sha256']} != "
                f"{ROUND1_CURRENT_ASSIGNMENT_SHA256}")
    inventory = qa["enumerated"]
    runs, unavailable = {}, []
    for cohort, cohort_runs in COHORTS.items():
        for run in cohort_runs:
            if only_run is not None and run != only_run:
                continue
            if (run, lane) not in found:
                unavailable.append({"cohort": cohort, "run": run, "reason": "absent from the replay root"})
                continue
            data = load_run_dir(found[(run, lane)], run, lane)
            observed, boot = data["observed"], boot_lower_middle(data["boot_ms"])
            unobserved = sorted(f for f in inventory if f not in observed)
            s_times, s_counts = static_times(sa["sets"], observed, qa["raw"], qa["async"], qa["factor"], boot)
            q_static, q_counts = static_times(qa["sets"], observed, qa["raw"], qa["async"], qa["factor"], boot)
            q_times, q_counts, claims = claim_queue(q_static, q_counts, qa["queue"], observed, qa["raw"], overhead_ms)
            runs[str(run)] = {
                "cohort": cohort,
                "boot_ms": boot,
                "queue_ratio": round(ratio_over(q_times, q_counts), 6),
                "static_ratio": round(ratio_over(s_times, s_counts), 6),
                "measured_ratio": measured.get((run, lane)),
                "partition_ms": {str(p): q_times[p] for p in sorted(q_times)},
                "static_partition_ms": {str(p): s_times[p] for p in sorted(s_times)},
                "claims": claims,
                "unobserved": unobserved,
                "unobserved_count": len(unobserved),
            }
    require(runs, f"lane {lane}: no available run to replay")
    return {
        "runs": runs,
        "unavailable": unavailable,
        "worst_queue_ratio": max(r["queue_ratio"] for r in runs.values()),
        "queue": qa["queue"],
        "queued": len(qa["queue"]),
        "queue_short": len(qa["queue"]) < qa["k"],
        "files": len(inventory),
        "assignment_sha256": qa["assignment_sha256"],
        "static_assignment_sha256": sa["assignment_sha256"],
        "factor_permille": qa["factor"],
        "k": qa["k"],
        "runner_sha256": qa["runner_sha256"],
    }


def cmd_replay(args):
    require(args.overhead_ms >= 0, "--overhead-ms must be non-negative")
    only_run = int(digits(args.run, "--run")) if args.run is not None else None
    if only_run is not None:
        cohort_of(only_run)
    lanes = [args.lane] if args.lane else list(LANES)
    found = discover(Path(args.root))
    measured = measured_ratios()
    live_runner = sha256_file(ROOT / RUNNER_REL)
    out = {"lanes": {}, "overhead_ms": args.overhead_ms, "filter": {"lane": args.lane, "run": only_run},
           "runner_sha256": live_runner}
    for lane in lanes:
        res = replay_lane(lane, found, args.overhead_ms, measured, only_run)
        require(res["runner_sha256"] == live_runner, "the copied runner differs from the live runner")
        out["lanes"][lane] = res
    out["k_by_lane"] = {lane: out["lanes"][lane]["k"] for lane in lanes}
    out["factor_permille"] = out["lanes"][lanes[0]]["factor_permille"]
    out["assignment_sha256"] = {lane: out["lanes"][lane]["assignment_sha256"] for lane in lanes}
    out["worst_queue_ratio"] = {lane: out["lanes"][lane]["worst_queue_ratio"] for lane in lanes}
    print(json.dumps(out, indent=2, sort_keys=True))
    return 0


# --- predict (P6, P10) --------------------------------------------------------------

def prereg_block(text, marker=PREREG_MARKER):
    m = re.findall(r"(?s)<!-- " + re.escape(marker) + r"-BEGIN -->\n(.*?)\n<!-- " + re.escape(marker) + r"-END -->",
                   text)
    require(len(m) == 1, f"expected one {marker} block, found {len(m)}")
    return m[0].strip()


def marked_json(text, name):
    m = re.findall(r"(?ms)^<!-- " + name + r"-JSON-BEGIN -->\n(.*?)\n<!-- " + name + r"-JSON-END -->$", text)
    require(len(m) == 1, f"expected one {name} JSON block, found {len(m)}")
    return json.loads(m[0])


def git(*args):
    proc = subprocess.run(["git", "-C", str(ROOT)] + list(args), capture_output=True, text=True, timeout=60)
    require(proc.returncode == 0, f"git {' '.join(args)} failed: {proc.stderr.strip()}")
    return proc.stdout


def gate_of(r8, r4, local):
    """P6 and P10 over the two full replays; pure, so --self-test can drive it.
    Component (a) covers GATE_LANES only (D-32); min and latest are reported."""
    replay, worst, coverage, worst_static = {}, {}, {}, {}
    for lane in LANES:
        runs8, runs4 = r8["lanes"][lane]["runs"], r4["lanes"][lane]["runs"]
        require(set(runs8) == set(runs4), f"{lane}: the 8000 and 4000 replays cover different runs")
        replay[lane] = {rid: {"cohort": x["cohort"], "queue_ratio_8000": x["queue_ratio"],
                              "queue_ratio_4000": runs4[rid]["queue_ratio"], "static_ratio": x["static_ratio"],
                              "measured_ratio": x["measured_ratio"]}
                        for rid, x in sorted(runs8.items())}
        worst[lane] = max(x["queue_ratio"] for x in runs8.values())
        coverage[lane] = sorted({x["cohort"] for x in runs8.values()})
        if lane not in GATE_LANES:
            worst_static[lane] = max(x["static_ratio"] for x in runs8.values())
    covered = all({"B4", "B5"} <= set(coverage[lane]) for lane in GATE_LANES)
    replay_ok = covered and all(worst[lane] <= GATE_MAX_RATIO for lane in GATE_LANES)
    b5 = [x for x in r8["lanes"]["current"]["runs"].values() if x["cohort"] == "B5"]
    require(len(b5) == len(COHORTS["B5"]), f"P10 needs the five B5 current-lane runs, have {len(b5)}")
    delta = statistics.median((max(x["partition_ms"].values()) - max(x["static_partition_ms"].values())) / 1000
                              for x in b5)
    st = local["self_test_seconds"]
    self_delta = max(st["head_env"] - st["baseline_env"], st["head_bin_bash"] - st["baseline_bin_bash"])
    predicted = round(B5_MEDIAN_S + delta + self_delta, 1)
    ci02_ok = predicted <= CI02_GATE_S
    return {
        "replay": replay,
        "worst_8000": worst,
        "worst_static": worst_static,
        "gated_lanes": list(GATE_LANES),
        "cohort_coverage": coverage,
        "gate_components": {"replay_current_worst_le_1_08": replay_ok, "ci02_predicted_le_510": ci02_ok},
        "gate": "PASS" if replay_ok and ci02_ok else "FAIL",
        "ci03_expectation": "EXPECTED_PASS" if replay_ok else "EXPECTED_MISS",
        "ci02_prediction": {"b5_median_s": B5_MEDIAN_S, "slowest_partition_delta_s": round(delta, 3),
                            "self_test_delta_s": self_delta, "predicted_ci02_median_s": predicted,
                            "ci02_expectation": "EXPECTED_PASS" if predicted <= CI02_LIMIT_S else "EXPECTED_MISS"},
    }


def cmd_predict(args):
    r8 = json.loads(Path(args.replay_8000).read_text())
    r4 = json.loads(Path(args.replay_4000).read_text())
    fetched = json.loads(Path(args.fetch).read_text())
    require(r8["overhead_ms"] == GATE_OVERHEAD_MS and r4["overhead_ms"] == INFO_OVERHEAD_MS,
            "replays must be at overhead 8000 and 4000")
    for r in (r8, r4):
        require(r["filter"] == {"lane": None, "run": None} and sorted(r["lanes"]) == sorted(LANES),
                "replays must cover every lane and run (no --lane or --run)")
        require(r["k_by_lane"] == LANE_K, f"k_by_lane {r['k_by_lane']} differs from the pre-registered {LANE_K}")
    require(r8["assignment_sha256"] == r4["assignment_sha256"], "the two replays used different assignments")
    require(r8["assignment_sha256"]["current"] == ROUND1_CURRENT_ASSIGNMENT_SHA256,
            "current-lane assignment differs from round 1")
    runner_sha = sha256_file(ROOT / RUNNER_REL)
    require(r8["runner_sha256"] == runner_sha and r4["runner_sha256"] == runner_sha, "runner changed since the replay")
    pre = args.pre_registration_commit
    require(re.fullmatch(r"[0-9a-f]{40}", pre) is not None, "pre-registration commit must be 40 lowercase hex")
    rule = prereg_block((ROOT / PLAN_REL).read_text())
    require(prereg_block(git("show", f"{pre}:{PLAN_REL}")) == rule,
            f"the {PREREG_MARKER} block at the pre-registration commit differs from the current plan")
    git("merge-base", "--is-ancestor", pre, "HEAD")
    round1_path = PHASE_DIR / ROUND1_PREDICTION_REL
    round1_sha = sha256_file(round1_path)
    require(round1_sha == ROUND1_PREDICTION_SHA256, f"{ROUND1_PREDICTION_REL} changed: {round1_sha}")
    round1 = marked_json(round1_path.read_text(), "B6-PREDICTION")
    require(round1["assignment_sha256"]["current"] == ROUND1_CURRENT_ASSIGNMENT_SHA256,
            "round 1's recorded current assignment differs from ROUND1_CURRENT_ASSIGNMENT_SHA256")
    b5 = json.loads((PHASE_DIR / MEASUREMENT_JSON["B5"]).read_text())
    require(b5["median_wall_s"] == B5_MEDIAN_S, f"B5 median {b5['median_wall_s']} != {B5_MEDIAN_S}")
    local = marked_json((PHASE_DIR / LOCAL_REL).read_text(), LOCAL_MARKER)
    require(local.get("lane_k") == LANE_K, f"{LOCAL_REL} lane_k {local.get('lane_k')} != {LANE_K}")
    for run, lanes in fetched["tsv_sha256"].items():
        for lane, parts in lanes.items():
            for p, h in parts.items():
                require(PINNED_TSV_SHA256.get((int(run), lane, int(p))) == h, f"fetch record {run}/{lane}/{p} is not pinned")
    stop = [line for line in rule.split("\n") if line.startswith("P9 ")]
    require(len(stop) == 1, f"no P9 line in the {PREREG_MARKER} block")
    disclosure = [line for line in rule.split("\n") if line.startswith("Disclosure (D-32).")]
    require(len(disclosure) == 1, f"no `Disclosure (D-32).` line in the {PREREG_MARKER} block")
    local_overhead = {}
    for lane in LANES:
        runs = [x for x in local["lane_runs"] if x["lane"] == lane]
        require(runs, f"{LOCAL_REL} has no {lane} lane run")
        vals = [x["overhead_mean_ms"] for x in runs if x["overhead_mean_ms"] is not None]
        local_overhead[lane] = round(sum(vals) / len(vals), 1) if vals else None
    g = gate_of(r8, r4, local)
    record = {
        "schema": PREDICTION_SCHEMA,
        "pre_registration_commit": pre,
        "pre_registered_rule": rule,
        "disclosure": disclosure[0],
        "runner_sha256": runner_sha,
        "tool_sha256": sha256_file(TOOL_PATH),
        "k_by_lane": r8["k_by_lane"],
        "gated_lanes": g["gated_lanes"],
        "round1": {"prediction": f".planning/phases/247-ci-critical-path-and-suite-lanes/{ROUND1_PREDICTION_REL}",
                   "prediction_sha256": round1_sha,
                   "current_assignment_sha256": ROUND1_CURRENT_ASSIGNMENT_SHA256,
                   "current_assignment_matches": r8["assignment_sha256"]["current"] == ROUND1_CURRENT_ASSIGNMENT_SHA256},
        "static_identity_main": local["static_identity_main"],
        "factor_permille": r8["factor_permille"],
        "assignment_sha256": r8["assignment_sha256"],
        "overhead_gate_ms": GATE_OVERHEAD_MS,
        "overhead_info_ms": INFO_OVERHEAD_MS,
        "cohorts": {c: list(r) for c, r in COHORTS.items()},
        "unavailable": fetched["unavailable"],
        "tsv_sha256": fetched["tsv_sha256"],
        "replay": g["replay"],
        "worst_8000": g["worst_8000"],
        "worst_static": g["worst_static"],
        "cohort_coverage": g["cohort_coverage"],
        "gate_components": g["gate_components"],
        "gate": g["gate"],
        "ci03_expectation": g["ci03_expectation"],
        "preflight_criteria": {"max_lane_ratio": float(PREFLIGHT_MAX_RATIO),
                               "max_pooled_mean_overhead_ms": PREFLIGHT_MAX_OVERHEAD_MS,
                               "lane_k": dict(LANE_K),
                               "evaluator": "tail_queue_replay.py preflight"},
        "stop_rule": stop[0],
        "local_overhead_ms": local_overhead,
        "ci02_prediction": g["ci02_prediction"],
    }
    print(json.dumps(record, indent=2, sort_keys=True))
    return 0


# --- preflight (P8) -----------------------------------------------------------------

def clean_log(text):
    """Strip each line's BOM, CR, ISO timestamp prefix and ANSI escapes."""
    out = []
    for line in text.split("\n"):
        line = line.lstrip("\ufeff").rstrip("\r")
        line = ANSI_RX.sub("", line)
        line = TS_RX.sub("", line, count=1)
        out.append(line)
    return out


def parse_lane_log(text):
    """The `Run tests` step section of one Build and test job log."""
    lines = clean_log(text)
    res = {"ratio": None, "queue": None, "claims": [], "reasons": []}
    starts = [i for i, line in enumerate(lines) if line == RUN_TESTS_GROUP]
    if len(starts) != 1:
        res["reasons"].append(f"expected one `{RUN_TESTS_GROUP}` step, found {len(starts)}")
        return res
    end = next((i for i in range(starts[0] + 1, len(lines)) if lines[i].startswith("##[group]Run ")), len(lines))
    section = lines[starts[0] + 1:end]
    ratios = [m.group(1) for m in (RATIO_ROW_RX.match(x) for x in section) if m]
    if len(ratios) != 1:
        res["reasons"].append(f"expected one `| max/min |` row, found {len(ratios)}")
    elif RATIO_VALUE_RX.fullmatch(ratios[0]) is None:
        res["reasons"].append(f"`| max/min |` value is {ratios[0]!r}")
    else:
        res["ratio"] = ratios[0]
    queues = [x for x in section if x.startswith(QUEUE_LINE_PREFIX)]
    if len(queues) != 1 or QUEUE_LINE_RX.fullmatch(queues[0]) is None:
        res["reasons"].append(f"expected one well-formed `tail queue K=` line, found {len(queues)}")
    else:
        m = QUEUE_LINE_RX.fullmatch(queues[0])
        res["queue"] = {"k": int(m.group(1)), "queued": int(m.group(2)), "claimed": int(m.group(3)),
                        "overhead_mean_ms": m.group(4)}
    for x in section:
        if x.startswith(CLAIM_LINE_PREFIX):
            m = CLAIM_LINE_RX.fullmatch(x)
            if m is None:
                res["reasons"].append(f"malformed claim line: {x[:160]!r}")
            else:
                res["claims"].append({"partition": int(m.group(1)), "seq": int(m.group(2)), "file": m.group(3),
                                      "exit": int(m.group(6)), "file_wall_ms": int(m.group(7)),
                                      "overhead_ms": int(m.group(8))})
    return res


def evaluate_preflight(conclusion, parsed):
    """P8 per lane (D-32, D-33): parsed is lane -> parse_lane_log result, or None
    when the job is missing. Every lane: ratio <= PREFLIGHT_MAX_RATIO and a queue
    line whose K is LANE_K[lane]. Lanes with K > 0 only: claim lines == queued,
    at least one claim line, and their claims feed the pooled-overhead rule."""
    reasons, lanes, pooled = [], {}, []
    if conclusion != "success":
        reasons.append(f"attempt 1 concluded {conclusion!r}, not success")
    for lane in LANES:
        p = parsed.get(lane)
        if p is None:
            reasons.append(f"{lane}: job `{LANE_JOB[lane]}` not found exactly once")
            lanes[lane] = None
            continue
        lane_reasons = list(p["reasons"])
        if p["ratio"] is not None and Decimal(p["ratio"]) > PREFLIGHT_MAX_RATIO:
            lane_reasons.append(f"max/min {p['ratio']} > {PREFLIGHT_MAX_RATIO}")
        q = p["queue"]
        if q is not None and q["k"] != LANE_K[lane]:
            lane_reasons.append(f"tail queue K={q['k']}, expected {LANE_K[lane]}")
        overheads = [c["overhead_ms"] for c in p["claims"]]
        if LANE_K[lane] > 0:
            if q is not None and len(p["claims"]) != q["queued"]:
                lane_reasons.append(f"{len(p['claims'])} claim lines != queued={q['queued']}")
            if not p["claims"]:
                lane_reasons.append("no claim line on a lane with K > 0")
            pooled.extend(overheads)
        lanes[lane] = {"ratio": p["ratio"], "queue": q, "claim_lines": len(p["claims"]),
                       "lane_k": LANE_K[lane], "claim_checks": LANE_K[lane] > 0,
                       "mean_overhead_ms": (round(sum(overheads) / len(overheads), 1) if overheads else None),
                       "reasons": lane_reasons}
        reasons.extend(f"{lane}: {r}" for r in lane_reasons)
    pooled_mean = round(sum(pooled) / len(pooled), 1) if pooled else None
    if pooled_mean is None:
        reasons.append("no claim lines on any lane with K > 0")
    elif sum(pooled) > PREFLIGHT_MAX_OVERHEAD_MS * len(pooled):
        reasons.append(f"pooled mean overhead {pooled_mean} ms > {PREFLIGHT_MAX_OVERHEAD_MS}")
    return {"lanes": lanes, "pooled_mean_overhead_ms": pooled_mean, "claim_lines": len(pooled),
            "verdict": "NO_GO" if reasons else "GO", "reasons": reasons}


def cmd_preflight(args):
    run = digits(args.run, "--run")
    attempt = gh_json("run-attempt-1", run)
    require(attempt.get("run_attempt") == 1, f"attempt object is attempt {attempt.get('run_attempt')}")
    jobs_doc = gh_json("attempt-1-jobs", run)
    jobs = jobs_doc.get("jobs", [])
    require(len(jobs) == jobs_doc.get("total_count"), "job listing is paginated")
    parsed = {}
    for lane in LANES:
        named = [j for j in jobs if j.get("name") == LANE_JOB[lane]]
        if len(named) != 1:
            parsed[lane] = None
            continue
        log = gh_read("job-log", digits(named[0]["id"], "job id")).decode("utf-8", errors="replace")
        parsed[lane] = parse_lane_log(log)
    result = evaluate_preflight(attempt.get("conclusion"), parsed)
    out = {"run": int(run), "attempt": 1, "head_sha": attempt.get("head_sha"),
           "conclusion": attempt.get("conclusion"), "criteria": {
               "max_lane_ratio": float(PREFLIGHT_MAX_RATIO),
               "max_pooled_mean_overhead_ms": PREFLIGHT_MAX_OVERHEAD_MS,
               "lane_k": dict(LANE_K)}}
    out.update(result)
    print(json.dumps(out, indent=2, sort_keys=True))
    return 0


# --- self-test ----------------------------------------------------------------------

def canned_lane_log(lane, ratio="1.08", claims=None, queued=None, overhead=3000, ratio_row=True, k=None):
    """A Build and test job log; by default K, claims and queued follow LANE_K
    (current 12/12/12, min and latest 0/0/0 with overhead_mean_ms=n/a)."""
    k = LANE_K[lane] if k is None else k
    claims = LANE_K[lane] if claims is None else claims
    queued = LANE_K[lane] if queued is None else queued
    ts = "2026-10-28T13:00:00.1234567Z "
    red, reset = "\x1b[31m", "\x1b[0m"
    lines = ["\ufeff" + ts + "Current runner version: '2.338.0'",
             ts + "##[group]Run bin/ci-test-partitions --self-test",
             ts + "##[endgroup]",
             # A stray claim line in the self-test step must never count.
             ts + "ci-test-partitions: claim partition=1 seq=1 file=test/x_test.exs start_ms=1 end_ms=2 "
                  "exit=0 file_wall_ms=1 overhead_ms=99999",
             ts + RUN_TESTS_GROUP,
             ts + "##[endgroup]"]
    for n in range(1, claims + 1):
        lines.append(ts + red + f"ci-test-partitions: claim partition={1 + n % 4} seq={n} "
                     f"file=test/q{n}_test.exs start_ms={n * 1000} end_ms={n * 1000 + 500} exit=0 "
                     f"file_wall_ms=400 overhead_ms={overhead}" + reset)
    lines.append(ts + f"ci-test-partitions: partition report (N=4)")
    lines.append(ts + "| total | - | 240 | - |")
    if ratio_row:
        lines.append(ts + red + f"| max/min | - | {ratio} | - |" + reset)
    lines.append(ts + f"ci-test-partitions: tail queue K={k} queued={queued} claimed={claims} "
                 f"overhead_mean_ms={overhead if claims else 'n/a'}")
    lines.append(ts + "##[group]Run actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9")
    lines.append(ts + "| max/min | - | 9.99 | - |")
    return "\n".join(lines) + "\n"


def self_test():
    checks = []

    def check(name, cond):
        require(cond, f"self-test failed: {name}")
        checks.append(name)

    def rejects(name, fn):
        try:
            fn()
        except CheckError:
            checks.append(name)
            return
        raise CheckError(f"self-test failed: {name} (accepted)")

    # P3: S + max(D, L) with the async floor, boot included.
    raw = {"s": 100, "a1": 1000, "a2": 50, "tiny": 1, "u": 70}
    am = {"s": False, "a1": True, "a2": True, "tiny": True, "u": False}
    sets = {1: ["s", "a1", "a2"], 2: ["tiny"], 3: ["u"], 4: ["s"]}
    t, c = static_times(sets, {"s": 100, "a1": 1000, "a2": 50, "tiny": 1}, raw, am, 292, 7)
    check("P3 long async L dominates D (7 + 100 + max(306, 1000))", t[1] == 1107)
    check("P3 async floor: D is at least 1", t[2] == 7 + 1)
    check("P3 unobserved file uses its raw lane weight", t[3] == 77)
    many = {f"m{i}": 100 for i in range(10)}
    t2, _ = static_times({1: sorted(many), 2: [], 3: [], 4: []}, many, many, {f: True for f in many}, 292, 0)
    check("P3 discount dominates a short L (floor(1000 * 292 / 1000) > 100)",
          t2[1] == 292 and bin_cost(5000, 10000, 2000, 292) == 7920)
    check("P3 no async means no D", bin_cost(7, 0, 0, 292) == 7)
    # Boot: the lower middle of four sorted values.
    check("boot lower middle", boot_lower_middle([4, 1, 3, 2]) == 2 and boot_lower_middle([5, 9, 5, 1]) == 5
          and boot_lower_middle([2100, 4400, 3000, 3000]) == 3000)
    rejects("boot needs four values", lambda: boot_lower_middle([1, 2, 3]))
    # P4: earliest-free claiming, ties to the lowest partition.
    raw4 = {"qa": 7, "qb": 3, "qc": 1}
    tq, cq, claims = claim_queue({1: 10, 2: 5, 3: 5, 4: 20}, {1: 1, 2: 1, 3: 1, 4: 1}, ["qa", "qb", "qc"], {}, raw4, 0)
    check("P4 tie goes to the lowest partition, then the smallest T",
          claims == {"qa": 2, "qb": 3, "qc": 3} and tq == {1: 10, 2: 12, 3: 9, 4: 20})
    tq, _, claims = claim_queue({1: 10, 2: 5, 3: 5, 4: 20}, {1: 1, 2: 1, 3: 1, 4: 1}, ["qa", "qb", "qc"],
                                {"qa": 2}, raw4, 4)
    check("P4 adds observed wall plus overhead", claims == {"qa": 2, "qb": 3, "qc": 1} and tq[2] == 11 and tq[1] == 15)
    _, cq, claims = claim_queue({1: 0, 2: 9, 3: 9, 4: 9}, {1: 0, 2: 1, 3: 1, 4: 1}, ["qa"], {}, raw4, 0)
    check("P4 an empty static partition claims first", claims == {"qa": 1} and cq[1] == 1)
    # P5.
    check("P5 ratio", abs(ratio_over({1: 10, 2: 12, 3: 9, 4: 20}, {1: 1, 2: 1, 3: 1, 4: 1}) - 20 / 9) < 1e-12)
    rejects("P5 fails on a partition with no file and no claim",
            lambda: ratio_over({1: 10, 2: 3, 3: 9, 4: 20}, {1: 1, 2: 0, 3: 1, 4: 1}))
    rejects("P5 fails on a missing partition", lambda: ratio_over({1: 10, 2: 3, 3: 9}, {1: 1, 2: 1, 3: 1}))
    # Strict TSV parsing.
    good = b"# threadline.partition-timings/1 partition=2 lane=min boot_ms=5 wall_ms=10\ntest/a_test.exs\t3\t2\n"
    check("strict TSV parses", parse_tsv_strict(good, "min", 2)["rows"] == {"test/a_test.exs": 3})
    rejects("strict TSV rejects a Unicode digit in a row",
            lambda: parse_tsv_strict(good.replace(b"\t3\t", "\t\u0663\t".encode()), "min", 2))
    rejects("strict TSV rejects a Unicode digit in the header",
            lambda: parse_tsv_strict(good.replace(b"boot_ms=5", "boot_ms=\u0665".encode()), "min", 2))
    rejects("strict TSV rejects CRLF", lambda: parse_tsv_strict(good.replace(b"\n", b"\r\n"), "min", 2))
    rejects("strict TSV rejects a duplicate file", lambda: parse_tsv_strict(good + b"test/a_test.exs\t4\t2\n", "min", 2))
    rejects("strict TSV rejects a missing final newline", lambda: parse_tsv_strict(good[:-1], "min", 2))
    rejects("strict TSV rejects an empty record", lambda: parse_tsv_strict(good + b"\n", "min", 2))
    rejects("strict TSV rejects the wrong lane", lambda: parse_tsv_strict(good, "current", 2))
    rejects("strict TSV rejects the wrong partition", lambda: parse_tsv_strict(good, "min", 3))
    rejects("a file observed in two partitions is rejected", lambda: merge_observed(
        {1: {"rows": {"test/a_test.exs": 1}}, 2: {"rows": {"test/a_test.exs": 2}}}))
    # Digests and artifact shape.
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as zf:
        for p in range(1, N_PARTITIONS + 1):
            zf.writestr(TSV_NAMES[p - 1], good.replace(b"partition=2", f"partition={p}".encode()))
    zdata = buf.getvalue()
    check("digest match accepted", verify_digest(zdata, "sha256:" + sha256_bytes(zdata)) == "sha256:" + sha256_bytes(zdata))
    rejects("digest mismatch rejected", lambda: verify_digest(zdata, "sha256:" + sha256_bytes(b"other")))
    rejects("malformed digest rejected", lambda: verify_digest(zdata, sha256_bytes(zdata)))
    check("artifact with exactly four TSVs unpacks", sorted(unpack_artifact(zdata)) == [1, 2, 3, 4])
    buf2 = io.BytesIO()
    with zipfile.ZipFile(buf2, "w") as zf:
        zf.writestr("partition-timings-1.tsv", good)
        zf.writestr("../evil.tsv", good)
    rejects("artifact with other members rejected", lambda: unpack_artifact(buf2.getvalue()))
    # P8 preflight parsing and verdict.
    clean = clean_log("\ufeff2026-10-28T12:57:20.8268197Z \x1b[36;1m| max/min | - | 1.17 | - |\x1b[0m\r\n")
    check("timestamp, BOM, CR and ANSI stripped", clean[0] == "| max/min | - | 1.17 | - |")

    def verdict(conclusion="success", **per_lane):
        parsed = {lane: parse_lane_log(canned_lane_log(lane, **per_lane.get(lane, {}))) for lane in LANES}
        return evaluate_preflight(conclusion, parsed)

    go = verdict()
    check("preflight GO on a canned three-lane log", go["verdict"] == "GO" and go["pooled_mean_overhead_ms"] == 3000
          and go["claim_lines"] == 12 and all(go["lanes"][x]["ratio"] == "1.08" for x in LANES))
    check("preflight GO with K=0 on min and latest",
          go["verdict"] == "GO" and all(go["lanes"][x]["queue"]["k"] == 0 and go["lanes"][x]["queue"]["queued"] == 0
                                        and go["lanes"][x]["claim_lines"] == 0
                                        and go["lanes"][x]["queue"]["overhead_mean_ms"] == "n/a"
                                        and go["lanes"][x]["claim_checks"] is False for x in ("min", "latest"))
          and go["lanes"]["current"]["queue"]["k"] == 12 and go["lanes"]["current"]["claim_lines"] == 12)
    check("preflight NO_GO on K=12 on min", verdict(min={"k": 12})["verdict"] == "NO_GO")
    check("preflight NO_GO on K=12 with 12 claims on latest",
          verdict(latest={"k": 12, "claims": 12, "queued": 12})["verdict"] == "NO_GO")
    check("preflight NO_GO on K=0 on current",
          verdict(current={"k": 0, "claims": 0, "queued": 0})["verdict"] == "NO_GO")
    check("preflight GO at exactly 1.15 and 8000 on current",
          verdict(current={"ratio": "1.15", "overhead": 8000})["verdict"] == "GO")
    check("preflight GO on ratio 1.15 on current", verdict(current={"ratio": "1.15"})["verdict"] == "GO")
    check("preflight NO_GO on ratio 1.16 on current", verdict(current={"ratio": "1.16"})["verdict"] == "NO_GO")
    check("preflight GO on ratio 1.15 on a K=0 lane",
          verdict(min={"ratio": "1.15"}, latest={"ratio": "1.15"})["verdict"] == "GO")
    check("preflight NO_GO on ratio 1.16 on a K=0 lane", verdict(latest={"ratio": "1.16"})["verdict"] == "NO_GO"
          and verdict(min={"ratio": "1.16"})["verdict"] == "NO_GO")
    r = verdict(current={"overhead": 8001})
    check("preflight NO_GO on pooled overhead 8001", r["verdict"] == "NO_GO" and r["pooled_mean_overhead_ms"] == 8001)
    check("preflight NO_GO on a missing current claim line", verdict(current={"claims": 11})["verdict"] == "NO_GO")
    check("preflight NO_GO when current queued and claimed nothing (fails closed)",
          verdict(current={"claims": 0, "queued": 0})["verdict"] == "NO_GO")
    check("preflight NO_GO on a missing max/min row", verdict(current={"ratio_row": False})["verdict"] == "NO_GO")
    check("preflight NO_GO on a missing max/min row on a K=0 lane", verdict(min={"ratio_row": False})["verdict"] == "NO_GO")
    check("preflight NO_GO on an n/a ratio", verdict(current={"ratio": "n/a"})["verdict"] == "NO_GO")
    check("preflight NO_GO on K other than the lane's", verdict(current={"k": 4})["verdict"] == "NO_GO")
    check("preflight NO_GO when attempt 1 failed", verdict("failure")["verdict"] == "NO_GO")
    no_job = evaluate_preflight("success", {"current": parse_lane_log(canned_lane_log("current")),
                                            "min": parse_lane_log(canned_lane_log("min"))})
    check("preflight NO_GO on a missing lane job", no_job["verdict"] == "NO_GO")
    check("preflight NO_GO without a Run tests step",
          evaluate_preflight("success", {lane: parse_lane_log(canned_lane_log(lane).replace(RUN_TESTS_GROUP, "x"))
                                         for lane in LANES})["verdict"] == "NO_GO")
    bad = canned_lane_log("current").replace("overhead_ms=3000\x1b[0m\n", "overhead_ms=abc\x1b[0m\n", 1)
    check("preflight NO_GO on a malformed claim line",
          evaluate_preflight("success", {"current": parse_lane_log(bad), "min": parse_lane_log(canned_lane_log("min")),
                                         "latest": parse_lane_log(canned_lane_log("latest"))})["verdict"] == "NO_GO")
    # P6/P10 gate arithmetic on a synthetic replay.
    def synth(overhead_ratio, ci_extra, other_ratio=None, drop=()):
        """A full replay: current at overhead_ratio, min and latest at other_ratio
        (queue == static, K=0); `drop` removes (lane, cohort) pairs."""
        lanes = {}
        for lane in LANES:
            ratio = overhead_ratio if lane == "current" or other_ratio is None else other_ratio
            runs = {}
            for cohort, ids in COHORTS.items():
                if (lane, cohort) in drop:
                    continue
                for rid in ids:
                    runs[str(rid)] = {"cohort": cohort, "queue_ratio": ratio,
                                      "static_ratio": 1.2 if lane == "current" else ratio,
                                      "measured_ratio": 1.17,
                                      "partition_ms": {"1": 200000 + ci_extra, "2": 1, "3": 1, "4": 1},
                                      "static_partition_ms": {"1": 200000, "2": 1, "3": 1, "4": 1}}
            lanes[lane] = {"runs": runs}
        return {"lanes": lanes}
    local = {"self_test_seconds": {"baseline_env": 31, "baseline_bin_bash": 33, "head_env": 46, "head_bin_bash": 46}}
    g = gate_of(synth(1.05, 10000), synth(1.03, 0), local)
    check("gate PASS when both components hold", g["gate"] == "PASS" and g["ci03_expectation"] == "EXPECTED_PASS"
          and g["ci02_prediction"]["predicted_ci02_median_s"] == 482.0
          and g["ci02_prediction"]["self_test_delta_s"] == 15 and g["gated_lanes"] == ["current"])
    g = gate_of(synth(1.05, 10000, 1.2), synth(1.03, 0, 1.2), local)
    check("gate ignores min and latest replays (min and latest 1.2, current 1.05 -> PASS)",
          g["gate"] == "PASS" and g["gate_components"]["replay_current_worst_le_1_08"] is True
          and g["worst_8000"] == {"current": 1.05, "min": 1.2, "latest": 1.2}
          and g["worst_static"] == {"min": 1.2, "latest": 1.2})
    g = gate_of(synth(1.081, 0), synth(1.03, 0), local)
    check("gate FAIL on a current replay above 1.08", g["gate"] == "FAIL" and g["ci03_expectation"] == "EXPECTED_MISS"
          and g["gate_components"]["replay_current_worst_le_1_08"] is False)
    g = gate_of(synth(1.05, 10000, drop={("current", "B4")}), synth(1.03, 0, drop={("current", "B4")}), local)
    check("gate FAIL without a current B4 run", g["gate"] == "FAIL"
          and g["gate_components"]["replay_current_worst_le_1_08"] is False and g["cohort_coverage"]["current"] == ["B3", "B5"])
    g = gate_of(synth(1.05, 10000, drop={("min", "B4"), ("latest", "B5")}),
                synth(1.03, 0, drop={("min", "B4"), ("latest", "B5")}), local)
    check("gate coverage is required on the current lane only", g["gate"] == "PASS")
    g = gate_of(synth(1.05, 38100), synth(1.03, 0), local)
    check("gate FAIL on a predicted CI-02 median above 510 s", g["gate"] == "FAIL"
          and g["ci03_expectation"] == "EXPECTED_PASS" and g["ci02_prediction"]["ci02_expectation"] == "EXPECTED_PASS"
          and g["gate_components"] == {"replay_current_worst_le_1_08": True, "ci02_predicted_le_510": False})
    # P1 lift line (D-32): K and the count come from the runner's stdout.
    lift12 = ("ci-test-partitions: enumerated 3 files\n"
              "ci-test-partitions: tail queue: 12 files lifted (K=12), weight 91234 ms\n"
              "ci-test-partitions: partition 1: static 40 files, weight 1 ms\n")
    lift0 = "ci-test-partitions: tail queue: 0 files lifted (K=0), weight 0 ms\n"
    check("lift line parsed (K and the count from a canned stdout)",
          parse_lift_line(lift12, 12) == 12 and parse_lift_line(lift0, 0) == 0)
    rejects("lift line parsed: a missing line is rejected", lambda: parse_lift_line("ci-test-partitions: x\n", 0))
    rejects("lift line parsed: a doubled line is rejected", lambda: parse_lift_line(lift12 + lift12, 12))
    rejects("lift line parsed: a count that differs from the queue is rejected", lambda: parse_lift_line(lift12, 11))
    rejects("lift line parsed: a line inside other text is rejected",
            lambda: parse_lift_line("x " + lift0, 0))
    r2 = "x\n<!-- TQ-PREREG-2-BEGIN -->\n P1 b\n<!-- TQ-PREREG-2-END -->\n"
    check("TQ-PREREG-2 block extraction", prereg_block(r2) == "P1 b" and PREREG_MARKER == "TQ-PREREG-2")
    r1 = "x\n<!-- TQ-PREREG-BEGIN -->\n P1 a\n<!-- TQ-PREREG-END -->\n"
    check("TQ-PREREG block extraction (round-1 marker)", prereg_block(r1, "TQ-PREREG") == "P1 a")
    rejects("TQ-PREREG-2 block extraction rejects a round-1-only text", lambda: prereg_block(r1))
    rejects("TQ-PREREG-2 block extraction rejects two blocks", lambda: prereg_block(r2 + r2))
    check("LANE_K is current 12, min 0, latest 0 and only current is gated",
          LANE_K == {"current": 12, "min": 0, "latest": 0} and GATE_LANES == ("current",)
          and PREFLIGHT_MAX_RATIO == Decimal("1.15"))
    check("pinned map keys are P2 run, lane, partition",
          all(int(r) in COHORTS[cohort_of(r)] and lane in LANES and 1 <= p <= N_PARTITIONS
              and re.fullmatch(r"[0-9a-f]{64}", h) for (r, lane, p), h in PINNED_TSV_SHA256.items()))
    check("async regex", bool(ASYNC_RX.search("  use ExUnit.Case, async: true\n"))
          and not ASYNC_RX.search("  use ExUnit.Case, async: false\n"))
    print(json.dumps({"self_test": "pass", "checks": checks}, indent=2))
    return 0


def main(argv):
    if argv == ["--self-test"]:
        return self_test()
    parser = argparse.ArgumentParser(prog="tail_queue_replay.py")
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("fetch")
    p.add_argument("--out", required=True)
    p.add_argument("--print-pins", action="store_true")
    p = sub.add_parser("replay")
    p.add_argument("--root", required=True)
    p.add_argument("--overhead-ms", required=True, type=int)
    p.add_argument("--lane", choices=list(LANES))
    p.add_argument("--run")
    p = sub.add_parser("predict")
    p.add_argument("--replay-8000", required=True)
    p.add_argument("--replay-4000", required=True)
    p.add_argument("--fetch", required=True)
    p.add_argument("--pre-registration-commit", required=True)
    p = sub.add_parser("preflight")
    p.add_argument("--run", required=True)
    args = parser.parse_args(argv)
    return {"fetch": cmd_fetch, "replay": cmd_replay, "predict": cmd_predict,
            "preflight": cmd_preflight}[args.cmd](args)


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except ApiError as exc:
        print(json.dumps({"error": str(exc), "kind": "api"}), file=sys.stderr)
        sys.exit(3)
    except (CheckError, subprocess.SubprocessError, OSError, KeyError, ValueError, InvalidOperation) as exc:
        print(json.dumps({"error": str(exc)}), file=sys.stderr)
        sys.exit(1)
