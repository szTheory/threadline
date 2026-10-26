defmodule Threadline.OperatorSurface.EvidenceContract do
  @moduledoc false
  @ui ~w(page actions form overlay data display)
  @router "lib/threadline/operator_surface/router.ex"
  @routes ~w(/ /timeline /transactions/:id /rows/:table/:record_id /transactions/:id/history/:table/:record_id /actors/:kind/:id /coverage /evidence /exports /policy/redaction /policy/retention)
  @control ~r/\b(?:phx-(?!(?:debounce|key|target|update|value-[a-z-]+)=)[a-z-]+|data-tl-copy|navigate|patch|href|action)=(?:"[^"\n]*"|\{[^\n]*)/
  @probe ~r/\btest(?:\.skip|\.fixme)?\(\s*(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)/

  def sources(root) do
    patterns = [
      "lib/threadline/operator_surface/{ui,live,components}/**/*.ex",
      "lib/threadline/operator_surface/style/*.css",
      "examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts",
      "examples/threadline_phoenix/e2e/tests/operator-*.spec.ts"
    ]

    paths = [@router | Enum.flat_map(patterns, &Path.wildcard(Path.join(root, &1)))]

    Map.new(paths, fn path ->
      relative = Path.relative_to(path, root)
      {relative, File.read!(Path.join(root, relative))}
    end)
  end

  # Scan independently from both authored JSON files. Occurrence distinguishes
  # two identical controls in the same module; function clauses remain separate.
  def declarations(sources) do
    Enum.flat_map(sources, fn {path, text} ->
      path
      |> declaration_scans()
      |> Enum.flat_map(&scan_declarations(path, text, &1))
    end)
  end

  defp declaration_scans(@router) do
    [
      {"route", ~r/^\s*live\("[^"\n]+"[^\n]*/m},
      {"seam", ~r/^\s*(?:get|post)\("[^"\n]+"[^\n]*/m}
    ]
  end

  defp declaration_scans(path) do
    cond do
      String.ends_with?(path, ".spec.ts") ->
        [{"state", @probe}]

      String.ends_with?(path, ".ex") ->
        [{"control", @control} | primitive_scans(path)]

      true ->
        []
    end
  end

  defp primitive_scans(path) do
    if Enum.any?(@ui, &String.ends_with?(path, "/ui/#{&1}.ex")),
      do: [{"primitive", ~r/^\s*def [a-z_][a-z_0-9]*\([^\n]*/m}],
      else: []
  end

  defp scan_declarations(path, text, {kind, regex}) do
    {anchors, _counts} =
      Regex.scan(regex, text, capture: :first)
      |> Enum.map_reduce(%{}, fn [match], counts ->
        anchor = String.trim(match)
        occurrence = Map.get(counts, anchor, 0) + 1

        {%{"path" => path, "kind" => kind, "anchor" => anchor, "occurrence" => occurrence},
         Map.put(counts, anchor, occurrence)}
      end)

    anchors
  end

  def ids(inventory),
    do:
      Enum.map(inventory["routes"] ++ inventory["items"] ++ inventory["extraStates"], & &1["id"])

  def key(a), do: {a["path"], a["kind"], a["anchor"], a["occurrence"]}
  def nonblank?(s), do: is_binary(s) and String.trim(s) != ""

  def static_errors(inventory, checklist, sources) do
    items = inventory["routes"] ++ inventory["items"] ++ inventory["extraStates"]
    anchors = Enum.flat_map(checklist["items"], & &1["anchors"])
    expected = declarations(sources) |> Enum.map(&key/1) |> MapSet.new()
    mapped = anchors |> Enum.reject(&(&1["kind"] == "anchor")) |> Enum.map(&key/1)
    route_patterns = Enum.map(inventory["routes"], & &1["pattern"])

    [
      error_if(items == [] or inventory["items"] == [], "empty inventory"),
      error_if(Enum.sort(route_patterns) != Enum.sort(@routes), "exact eleven routes"),
      error_if(
        Enum.sort(ids(inventory)) != Enum.sort(Enum.map(checklist["items"], & &1["id"])),
        "checklist inventory IDs"
      ),
      error_if(
        length(ids(inventory)) != length(Enum.uniq(ids(inventory))),
        "unique inventory IDs"
      ),
      error_if(length(mapped) != length(Enum.uniq(mapped)), "one owner per declaration"),
      error_if(MapSet.new(mapped) != expected, "independent declaration coverage"),
      error_if(not valid_static_items?(items), "blank static field"),
      error_if(not valid_checklist_items?(checklist["items"]), "anchor or reasoned exclusion"),
      error_if(not Enum.all?(anchors, &valid_source_anchor?(&1, sources)), "source anchor")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp valid_static_items?(items) do
    Enum.all?(items, fn item ->
      nonblank?(item["id"]) and
        (nonblank?(item["label"]) or nonblank?(item["seedResolution"]) or
           nonblank?(item["state"]))
    end)
  end

  defp valid_checklist_items?(items) do
    Enum.all?(items, fn item ->
      nonblank?(item["kind"]) and (item["anchors"] != [] or nonblank?(item["exclusion"]))
    end)
  end

  defp valid_source_anchor?(anchor, sources) do
    source = sources[anchor["path"]] || ""

    is_integer(anchor["occurrence"]) and anchor["occurrence"] > 0 and
      nonblank?(anchor["anchor"]) and
      length(:binary.matches(source, anchor["anchor"])) >= anchor["occurrence"]
  end

  defp error_if(true, message), do: message
  defp error_if(false, _message), do: nil

  def findings(text) do
    text
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "| item:"))
    |> Enum.map(fn line ->
      [id, rank, owner, evidence, hash, disposition, reason] =
        line |> String.trim("|") |> String.split("|") |> Enum.map(&String.trim/1)

      %{
        "id" => String.replace_prefix(id, "item:", ""),
        "rank" => rank,
        "owner" => owner,
        "evidence" => evidence,
        "hash" => hash,
        "disposition" => disposition,
        "reason" => reason
      }
    end)
  end

  def finding_errors(rows, ids, catalog) do
    ranks = %{"high" => 0, "medium" => 1, "low" => 2, "coverage" => 3}

    checks = [
      {Enum.sort(Enum.map(rows, & &1["id"])) == Enum.sort(ids), "exact finding IDs"},
      {rows == Enum.sort_by(rows, &{ranks[&1["rank"]], &1["id"]}),
       "risk then stable ID ordering"},
      {Enum.all?(
         rows,
         &(Map.has_key?(ranks, &1["rank"]) and &1["owner"] in ~w(239 240 241 242 243))
       ), "rank and approved owner"},
      {Enum.all?(
         rows,
         &(&1["disposition"] in ~w(finding candidate debt accepted limited not-applicable) and
             nonblank?(&1["reason"]))
       ), "blank disposition or reason"},
      {Enum.all?(rows, fn row ->
         case catalog[row["evidence"]] do
           nil ->
             String.starts_with?(row["evidence"], "source:") and row["hash"] == "-" and
               row["disposition"] in ~w(limited not-applicable debt)

           hash ->
             hash == row["hash"]
         end
       end), "capture ID/hash or explicit source limitation"}
    ]

    for {false, error} <- checks, do: error
  end

  def file_hash(path), do: :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)

  def output_errors(capture, bundle) do
    path = Path.expand(capture["outputPath"], bundle)

    cond do
      not String.starts_with?(path, Path.expand(bundle) <> "/") -> ["output containment"]
      not File.regular?(path) -> ["missing output"]
      file_hash(path) != capture["outputSha256"] -> ["output byte hash"]
      true -> []
    end
  end

  def required_path!(env) do
    path = System.get_env(env)

    if not nonblank?(path) or not File.regular?(path),
      do: raise(ArgumentError, "#{env} requires an existing file")

    Path.expand(path)
  end

  def live_catalog!(root, manifest, findings) do
    bundles =
      Regex.scan(~r/^bundle_path: (.+)$/m, findings, capture: :all_but_first)
      |> List.flatten()
      |> Enum.map(&Path.expand(&1, root))

    if bundles == [] or Path.dirname(manifest) not in bundles,
      do: raise(ArgumentError, "accepted manifest bundle is missing")

    script = ~S"""
    const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),crypto=require('node:crypto');
    const root=process.cwd(), bundles=JSON.parse(process.argv[1]), mainPath=process.argv[2];
    const {candidateIdentity,serializeManifest}=require('./examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts');
    const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
    const orderedCSS=['01_tokens.css','02_base_shell.css','03_page_home.css','04_controls.css','05_feedback.css','06_layout_primitives.css','07_find_detail.css','08_overlays_motion.css','09_responsive.css'].map(n=>fs.readFileSync(path.join(root,'lib/threadline/operator_surface/style',n),'utf8')).join('');
    const catalog={}; let first, main; const selected=fs.realpathSync(mainPath);
    for(const bundle of bundles){
      const dir=fs.realpathSync(bundle);
      assert.ok(dir.startsWith(path.join(root,'examples/threadline_phoenix/e2e/artifacts/operator-evidence/') ));
      const names=[...new Set([...fs.readdirSync(dir).filter(n=>n.endsWith('-manifest.json')||n==='manifest.json'), ...(path.dirname(selected)===dir ? [path.basename(selected)] : [])])].sort();
      assert.ok(names.length>0);
      for(const name of names){
        const manifestFile=fs.realpathSync(path.join(dir,name));assert.equal(path.dirname(manifestFile),dir);
        const bytes=fs.readFileSync(manifestFile,'utf8'),m=JSON.parse(bytes),current=candidateIdentity(root,m.baseSha);
        assert.equal(serializeManifest(m),bytes);
        if(manifestFile===selected)main=m;
        assert.equal(m.candidateDiffDigest,current.candidateDiffDigest);
        assert.deepEqual(m.candidateChanges,current.candidateChanges);
        const end=current.candidateAncestry.indexOf(m.candidateHead);
        assert.ok(end>=0); assert.deepEqual(m.candidateAncestry,current.candidateAncestry.slice(0,end+1));
        if(!first)first=m;
        assert.equal(m.baseSha,first.baseSha);assert.deepEqual(m.fixture,first.fixture);
        const seedRoot=path.join(root,'examples/threadline_phoenix/lib/threadline_phoenix/demo'),seedHash=crypto.createHash('sha256');
        const seedFiles=['seed.ex','manifest.ex',...fs.readdirSync(path.join(seedRoot,'seed'),{recursive:true}).map(n=>'seed/'+n)].sort();
        for(const file of seedFiles)seedHash.update(file).update('\0').update(fs.readFileSync(path.join(seedRoot,file)));
        seedHash.update('config/test.exs\0').update(fs.readFileSync(path.join(root,'examples/threadline_phoenix/config/test.exs')));
        assert.equal(m.fixture.seedManifestSha256,seedHash.digest('hex'));
        for(const c of m.captures){
          const file=fs.realpathSync(path.resolve(dir,c.outputPath));assert.ok(file.startsWith(dir+'/'));
          assert.equal(sha(fs.readFileSync(file)),c.outputSha256);
          const ref=path.basename(dir)+'#'+c.id;
          if(catalog[ref])assert.equal(catalog[ref],c.outputSha256);catalog[ref]=c.outputSha256;
          for(const a of c.assets){
            const local=a.url.startsWith('inline:')?sha(orderedCSS):sha(fs.readFileSync(path.resolve(root,a.localPath)));
            assert.equal(a.localSha256,local);assert.equal(a.servedSha256,local);
          }
        }
      }
    }
    assert.ok(main, 'Selected manifest was not validated inside an accepted bundle');
    const inventory=JSON.parse(fs.readFileSync(path.join(root,'test/fixtures/operator_surface/route-inventory.json'),'utf8'));
    for(const route of inventory.routes)for(const width of [1280,768,375])for(const kind of ['shell','content','observation','scorecard']){
      assert.ok(main.captures.some(c=>c.id===route.id+'__dark-'+width+'-'+kind), 'Missing direct route cell '+route.id+' '+width+' '+kind);
    }
    assert.equal(main.captures.length,135);
    process.stdout.write(JSON.stringify(catalog));
    """

    {output, status} =
      System.cmd(
        Path.join(root, "examples/threadline_phoenix/e2e/node_modules/.bin/tsx"),
        ["-e", script, Jason.encode!(bundles), manifest],
        cd: root,
        stderr_to_stdout: true
      )

    if status != 0, do: raise(ArgumentError, "live source/asset/output custody failed: #{output}")
    Jason.decode!(output)
  end

  def preview_errors(receipt, manifest, root) do
    [
      error_if(not typed_preview_metadata?(receipt), "typed preview metadata"),
      error_if(not typed_preview_identity?(receipt["identity"] || %{}), "typed preview identity"),
      error_if(
        not typed_fields?(receipt["isolationManifest"], ~w(path sha256)),
        "allowlisted isolation manifest"
      ),
      error_if(
        not typed_fields?(receipt["lifecycle"], ~w(script stop reopen policy sha256)),
        "allowlisted lifecycle metadata"
      ),
      error_if(not allowed_preview_fields?(receipt), "allowlisted preview metadata"),
      error_if(secret_fields?(receipt), "sensitive preview metadata"),
      error_if(
        not allowed_identity_fields?(receipt["identity"] || %{}),
        "allowlisted preview identity"
      ),
      error_if(
        not valid_local_assets?(receipt["assets"] || []),
        "allowlisted local preview assets"
      ),
      error_if(not preview_assets_match?(receipt, manifest), "preview accepted asset identity"),
      error_if(not loopback_preview_url?(receipt["url"] || ""), "loopback preview URL"),
      error_if(not valid_preview_pid?(receipt["pid"]), "live preview PID"),
      error_if(
        not preview_source_identity?(receipt, manifest, root),
        "preview source/fixture identity"
      ),
      error_if(not safe_preview_database?(receipt), "safe preview database"),
      error_if(not preview_readiness?(receipt["checks"]), "preview readiness proof")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp typed_preview_metadata?(receipt) do
    receipt["schemaVersion"] == 1 and
      typed_fields?(
        Map.take(
          receipt,
          ~w(url worktree branch partition database capturedAt manifestPath inventoryPath)
        ),
        ~w(url worktree branch partition database capturedAt manifestPath inventoryPath)
      )
  end

  defp typed_preview_identity?(identity) do
    typed_fields?(
      Map.take(identity, ~w(baseSha candidateDiffDigest candidateHead)),
      ~w(baseSha candidateDiffDigest candidateHead)
    ) and
      is_list(identity["candidateAncestry"]) and
      Enum.all?(identity["candidateAncestry"], &is_binary/1) and
      typed_fields?(identity["fixture"], ~w(scenario version seedManifestSha256 semanticId))
  end

  defp allowed_preview_fields?(receipt) do
    allowed =
      ~w(schemaVersion url pid worktree branch isolationManifest partition database identity checks assets capturedAt lifecycle manifestPath inventoryPath)

    Enum.all?(Map.keys(receipt), &(&1 in allowed))
  end

  defp allowed_identity_fields?(identity) do
    Enum.sort(Map.keys(identity)) ==
      Enum.sort(~w(baseSha candidateDiffDigest fixture candidateHead candidateAncestry))
  end

  defp valid_local_assets?(assets) do
    Enum.all?(assets, &valid_local_asset?/1)
  end

  defp valid_local_asset?(asset) do
    url = URI.parse(asset["url"] || "")
    allowed = ~w(url status contentType servedSha256 localPath localSha256)

    Enum.sort(Map.keys(asset)) == Enum.sort(allowed) and asset["status"] == 200 and
      typed_fields?(
        Map.delete(asset, "status"),
        ~w(url contentType servedSha256 localPath localSha256)
      ) and
      is_nil(url.userinfo) and is_nil(url.query) and
      (url.scheme == "inline" or (url.scheme == "http" and url.host == "127.0.0.1"))
  end

  defp preview_assets_match?(receipt, manifest) do
    assets = receipt["assets"] || []
    capture_assets = get_in(manifest, ["captures", Access.at(0), "assets"]) || []

    Enum.sort(Enum.map(assets, &preview_asset_key/1)) ==
      Enum.sort(Enum.map(capture_assets, &preview_asset_key/1)) and assets != []
  end

  defp preview_asset_key(asset),
    do: {asset["localPath"], asset["localSha256"], asset["servedSha256"]}

  defp loopback_preview_url?(value) do
    url = URI.parse(value)

    url.scheme == "http" and url.host == "127.0.0.1" and is_integer(url.port) and
      url.path in [nil, "", "/"] and is_nil(url.userinfo) and is_nil(url.query)
  end

  defp valid_preview_pid?(pid), do: is_integer(pid) and pid > 1

  defp preview_source_identity?(receipt, manifest, root) do
    identity = receipt["identity"] || %{}

    receipt["worktree"] == root and identity["baseSha"] == manifest["baseSha"] and
      identity["candidateDiffDigest"] == manifest["candidateDiffDigest"] and
      identity["fixture"] == manifest["fixture"]
  end

  defp safe_preview_database?(receipt) do
    is_binary(receipt["partition"]) and
      String.match?(receipt["partition"], ~r/^operator_[A-Za-z0-9_]+$/) and
      receipt["database"] == "threadline_phoenix_test#{receipt["partition"]}"
  end

  defp preview_readiness?(checks) do
    checks == %{
      "unauthenticated" => "local-login-redirect",
      "audit" => "authenticated-shell",
      "deepLink" => "authenticated-transaction",
      "binding" => "127.0.0.1",
      "database" => "verified-pid-connection"
    }
  end

  defp typed_fields?(value, keys) when is_map(value),
    do:
      Enum.sort(Map.keys(value)) == Enum.sort(keys) and
        Enum.all?(Map.values(value), &(is_binary(&1) and String.trim(&1) != ""))

  defp typed_fields?(_, _), do: false

  def secret_fields?(value) when is_map(value),
    do:
      Enum.any?(value, fn {key, v} ->
        Regex.match?(
          ~r/password|cookie|csrf|authorization|token|secret|credential|api[_-]?key|responseHeaders|responseBody/i,
          key
        ) or
          secret_fields?(v)
      end)

  def secret_fields?(value) when is_list(value), do: Enum.any?(value, &secret_fields?/1)
  def secret_fields?(_), do: false

  def verify_preview!(root, receipt_path) do
    script = ~S"""
    const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),crypto=require('node:crypto'),cp=require('node:child_process');
    const r=JSON.parse(fs.readFileSync(process.argv[1],'utf8')),root=process.cwd();
    const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
    const run=(cmd,args)=>cp.execFileSync(cmd,args,{encoding:'utf8',env:{...process.env,PGPASSWORD:process.env.DB_PASSWORD||'postgres'}});
    const cwd=run('lsof',['-a','-p',String(r.pid),'-d','cwd','-Fn']);assert.ok(cwd.split('\n').includes('n'+path.join(root,'examples/threadline_phoenix')));
    const listener=run('lsof',['-nP','-a','-p',String(r.pid),'-iTCP:'+new URL(r.url).port,'-sTCP:LISTEN']);assert.ok(listener.includes('127.0.0.1:'+new URL(r.url).port));assert.ok(!listener.includes('*:'));
    const connections=run('lsof',['-nP','-a','-p',String(r.pid),'-iTCP','-sTCP:ESTABLISHED']);
    const ports=[...connections.matchAll(/127\.0\.0\.1:(\d+)->127\.0\.0\.1:5432/g)].map(m=>Number(m[1]));assert.ok(ports.length>0,'PID has no local database connection');
    const db=run('psql',['-X','-h','127.0.0.1','-p','5432','-U','postgres','-d','postgres','-Atqc','SELECT DISTINCT datname FROM pg_stat_activity WHERE client_port IN ('+ports.join(',')+')']).trim();assert.equal(db,r.database,'PID connected to wrong database');
    const {candidateIdentity}=require('./examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts');
    const current=candidateIdentity(root,r.identity.baseSha);assert.equal(current.candidateDiffDigest,r.identity.candidateDiffDigest);
    const {chromium}=require('./examples/threadline_phoenix/e2e/node_modules/playwright');
    const {seedPaths}=require('./examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts');
    let stage='launch';
    (async()=>{const browser=await chromium.launch({headless:true});try{
      const unauth=await browser.newContext({baseURL:r.url});const response=await unauth.request.get('/audit',{maxRedirects:0});assert.ok([302,303].includes(response.status()));const target=new URL(response.headers()['location'],r.url);assert.equal(target.origin,r.url);assert.equal(target.pathname,'/users/log_in');await unauth.close();const context=await browser.newContext({baseURL:r.url});
      stage='seeded login';const page=await context.newPage();await page.goto('/users/log_in');await page.locator('#login_form').getByLabel('Email').fill('admin@example.com');await page.locator('#login_form').getByLabel('Password').fill(process.env.DEMO_SEED_PASSWORD||'password123456');await page.locator('#login_form').getByRole('button',{name:/log in/i}).click();await page.waitForURL(r.url+'/');stage='audit/deep link';let res=await page.goto('/audit');assert.equal(res.status(),200);await page.locator('.threadline-ui #tl-main').waitFor();const paths=await seedPaths(page);res=await page.goto(paths.transaction);assert.equal(res.status(),200);await page.locator('.threadline-ui #tl-main').waitFor();await page.getByRole('heading',{name:'Transaction',exact:true}).first().waitFor();stage='served assets';
      const styles=await page.locator('style').allTextContents();
      const external=await page.evaluate(()=>performance.getEntriesByType('resource').map(entry=>new URL(entry.name).pathname).filter(name=>name.startsWith('/assets/')));
      for(const a of r.assets){if(a.url.startsWith('inline:')){stage='inline CSS hash';assert.ok(styles.some(s=>sha(s)===a.servedSha256),'served inline CSS differs');}else{const pathname=new URL(a.url).pathname;stage='asset reference '+pathname;assert.ok(external.map(x=>new URL(x,r.url).pathname).includes(pathname));stage='asset response hash '+pathname;const response=await context.request.get(pathname);assert.equal(response.status(),200);assert.equal(sha(await response.body()),a.servedSha256);stage='asset local hash '+pathname;assert.equal(sha(fs.readFileSync(path.join(root,a.localPath))),a.localSha256);}}
      assert.ok(r.assets.length>=3);process.stdout.write('preview verified');
    }finally{await browser.close();}})().catch(()=>{process.stderr.write('Preview runtime custody check failed at '+stage);process.exitCode=1;});
    """

    {output, status} =
      System.cmd(
        Path.join(root, "examples/threadline_phoenix/e2e/node_modules/.bin/tsx"),
        ["-e", script, receipt_path],
        cd: root,
        env: [
          {"PLAYWRIGHT_BROWSERS_PATH",
           Path.join(System.tmp_dir!(), "threadline-playwright-cache")}
        ],
        stderr_to_stdout: true
      )

    if status != 0,
      do: raise(ArgumentError, "preview PID/port/database/assets/auth custody failed: #{output}")

    output
  end
end

defmodule Threadline.OperatorSurface.OperatorEvidenceContractTest do
  use ExUnit.Case, async: true
  @moduletag :repo_contract
  alias Threadline.OperatorSurface.EvidenceContract, as: Contract

  @root Path.expand("../../..", __DIR__)
  @fixtures Path.join(@root, "test/fixtures/operator_surface")

  test "generic inventories close every independently discovered declaration" do
    inventory = Jason.decode!(File.read!(Path.join(@fixtures, "route-inventory.json")))

    assert inventory["items"] != nil && inventory["items"] != [],
           "route inventory must declare primitive, control and state items"

    assert File.regular?(Path.join(@fixtures, "source-surface-checklist.json")),
           "independent source checklist must exist"

    assert Contract.static_errors(inventory, checklist(), Contract.sources(@root)) == []
  end

  defp inventory, do: Jason.decode!(File.read!(Path.join(@fixtures, "route-inventory.json")))

  defp checklist,
    do: Jason.decode!(File.read!(Path.join(@fixtures, "source-surface-checklist.json")))

  test "omitting an item from both inventories still fails independent source coverage" do
    i = inventory()
    c = checklist()
    item = Enum.find(i["items"], &(&1["kind"] == "control"))
    i = Map.update!(i, "items", &Enum.reject(&1, fn a -> a["id"] == item["id"] end))
    c = Map.update!(c, "items", &Enum.reject(&1, fn a -> a["id"] == item["id"] end))

    assert "independent declaration coverage" in Contract.static_errors(
             i,
             c,
             Contract.sources(@root)
           )
  end

  test "real route, function, control and named probe additions require declarations" do
    sources = Contract.sources(@root)

    additions = [
      {"lib/threadline/operator_surface/router.ex", "\n live(\"/unlisted\", NewLive, :index)\n"},
      {"lib/threadline/operator_surface/ui/page.ex", "\n def unlisted(assigns) do\n end\n"},
      {"lib/threadline/operator_surface/live/start_live.ex",
       "\n<button phx-click=\"unlisted-control\">Open</button>\n"},
      {"lib/threadline/operator_surface/live/transaction_live.ex",
       "\n<div phx-viewport-bottom=\"unlisted-page\"></div>\n"},
      {"examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts",
       "\ntest(\"unlisted denial probe\", async () => {});\n"}
    ]

    for {path, addition} <- additions do
      changed = Map.update!(sources, path, &(&1 <> addition))

      assert "independent declaration coverage" in Contract.static_errors(
               inventory(),
               checklist(),
               changed
             )
    end
  end

  test "missing routes, duplicate IDs, blank labels and broken anchors fail closed" do
    i = inventory()
    c = checklist()
    sources = Contract.sources(@root)

    assert "exact eleven routes" in Contract.static_errors(
             Map.update!(i, "routes", &tl/1),
             c,
             sources
           )

    assert "unique inventory IDs" in Contract.static_errors(
             Map.update!(i, "items", &[hd(&1) | &1]),
             c,
             sources
           )

    assert "blank static field" in Contract.static_errors(
             put_in(i, ["items", Access.at(0), "label"], ""),
             c,
             sources
           )

    assert "source anchor" in Contract.static_errors(
             i,
             put_in(
               c,
               ["items", Access.at(0), "anchors", Access.at(0), "anchor"],
               "unlisted-source-anchor"
             ),
             sources
           )

    assert "empty inventory" in Contract.static_errors(
             %{"routes" => [], "items" => [], "extraStates" => []},
             %{"items" => []},
             sources
           )
  end

  test "finding links reject missing IDs, blank dispositions, invented hashes and source-only defects" do
    row = %{
      "id" => "control.copy.value",
      "rank" => "high",
      "owner" => "240",
      "evidence" => "bundle#copy",
      "hash" => "a",
      "disposition" => "finding",
      "reason" => "Exact copy did not complete"
    }

    catalog = %{"bundle#copy" => "a"}
    assert Contract.finding_errors([row], [row["id"]], catalog) == []
    assert "exact finding IDs" in Contract.finding_errors([], [row["id"]], catalog)

    assert "blank disposition or reason" in Contract.finding_errors(
             [%{row | "disposition" => ""}],
             [row["id"]],
             catalog
           )

    assert "capture ID/hash or explicit source limitation" in Contract.finding_errors(
             [%{row | "hash" => "wrong"}],
             [row["id"]],
             catalog
           )

    assert "capture ID/hash or explicit source limitation" in Contract.finding_errors(
             [%{row | "evidence" => "source:copy", "hash" => "-"}],
             [row["id"]],
             catalog
           )

    assert "rank and approved owner" in Contract.finding_errors(
             [%{row | "owner" => "999"}],
             [row["id"]],
             catalog
           )
  end

  test "equal-risk ordering is deterministic and reversed rows are rejected" do
    rows =
      for id <- ~w(control.a control.b),
          do: %{
            "id" => id,
            "rank" => "medium",
            "owner" => "239",
            "evidence" => "source:lib/threadline/operator_surface/ui/page.ex",
            "hash" => "-",
            "disposition" => "limited",
            "reason" => "Not observed"
          }

    ids = Enum.map(rows, & &1["id"])
    assert Contract.finding_errors(rows, ids, %{}) == []
    assert "risk then stable ID ordering" in Contract.finding_errors(Enum.reverse(rows), ids, %{})
  end

  @tag :tmp_dir
  test "output integrity checks actual bytes, absent artifacts and escaping paths", %{
    tmp_dir: dir
  } do
    file = Path.join(dir, "shell.png")
    File.write!(file, "rendered bytes")
    capture = %{"outputPath" => "shell.png", "outputSha256" => Contract.file_hash(file)}
    assert Contract.output_errors(capture, dir) == []
    File.write!(file, "changed pixels")
    assert Contract.output_errors(capture, dir) == ["output byte hash"]

    assert Contract.output_errors(%{capture | "outputPath" => "missing.png"}, dir) == [
             "missing output"
           ]

    assert Contract.output_errors(%{capture | "outputPath" => "../shell.png"}, dir) == [
             "output containment"
           ]
  end

  test "preview custody rejects remote URLs, invalid PID and unsafe database targets" do
    manifest = %{
      "baseSha" => "base",
      "candidateDiffDigest" => "digest",
      "fixture" => %{"semanticId" => "fixture"}
    }

    receipt = %{
      "url" => "https://example.com",
      "pid" => 0,
      "partition" => "shared",
      "database" => "production",
      "worktree" => "other"
    }

    errors = Contract.preview_errors(receipt, manifest, @root)
    assert "loopback preview URL" in errors
    assert "live preview PID" in errors
    assert "safe preview database" in errors
    assert "preview source/fixture identity" in errors

    assert "sensitive preview metadata" in Contract.preview_errors(
             Map.put(receipt, "cookie", "session"),
             manifest,
             @root
           )

    assert "allowlisted preview metadata" in Contract.preview_errors(
             Map.put(receipt, "response", "raw HTML"),
             manifest,
             @root
           )
  end

  test "valid preview receipts reject nested secrets, bodies and untyped metadata" do
    asset = %{
      "url" => "http://127.0.0.1:4109/assets/app.js",
      "status" => 200,
      "contentType" => "text/javascript",
      "servedSha256" => "hash",
      "localSha256" => "hash",
      "localPath" => "app.js"
    }

    fixture = %{
      "scenario" => "demo",
      "version" => "1",
      "seedManifestSha256" => "seed",
      "semanticId" => "fixture"
    }

    manifest = %{
      "baseSha" => "base",
      "candidateDiffDigest" => "digest",
      "fixture" => fixture,
      "captures" => [%{"assets" => [asset]}]
    }

    receipt = %{
      "schemaVersion" => 1,
      "url" => "http://127.0.0.1:4109",
      "pid" => 777_777,
      "worktree" => @root,
      "branch" => "preview",
      "partition" => "operator_contract",
      "database" => "threadline_phoenix_testoperator_contract",
      "capturedAt" => "2026-10-09T00:00:00Z",
      "manifestPath" => "manifest.json",
      "inventoryPath" => "inventory.json",
      "identity" => %{
        "baseSha" => "base",
        "candidateDiffDigest" => "digest",
        "fixture" => fixture,
        "candidateHead" => "head",
        "candidateAncestry" => ["head"]
      },
      "isolationManifest" => %{"path" => "receipt.json", "sha256" => "hash"},
      "lifecycle" => %{
        "script" => "preview.py",
        "stop" => "stop",
        "reopen" => "reopen",
        "policy" => "guarded",
        "sha256" => "hash"
      },
      "checks" => %{
        "unauthenticated" => "local-login-redirect",
        "audit" => "authenticated-shell",
        "deepLink" => "authenticated-transaction",
        "binding" => "127.0.0.1",
        "database" => "verified-pid-connection"
      },
      "assets" => [asset]
    }

    assert Contract.preview_errors(receipt, manifest, @root) == []

    for field <- ["lifecycle", "isolationManifest"],
        key <- ~w(token secret credentials api_key response responseBody responseHeaders unknown) do
      changed = update_in(receipt[field], &Map.put(&1, key, "not allowed"))
      refute Contract.preview_errors(changed, manifest, @root) == [], "accepted #{field}.#{key}"
    end

    for field <- ~w(branch capturedAt manifestPath inventoryPath) do
      refute Contract.preview_errors(Map.put(receipt, field, %{"body" => "raw"}), manifest, @root) ==
               []
    end

    refute Contract.preview_errors(
             put_in(receipt, ["assets", Access.at(0), "status"], %{"body" => "raw"}),
             manifest,
             @root
           ) == []

    for [field, key] <- [["lifecycle", "stop"], ["isolationManifest", "path"]] do
      changed = put_in(receipt, [field, key], %{"nested" => "body"})
      refute Contract.preview_errors(changed, manifest, @root) == []
    end
  end

  test "requested live evidence fails closed and validates retained custody" do
    case System.get_env("THREADLINE_OPERATOR_EVIDENCE_MODE") do
      nil ->
        :ok

      "live" ->
        manifest_path = Contract.required_path!("THREADLINE_OPERATOR_EVIDENCE_MANIFEST")
        findings_path = Contract.required_path!("THREADLINE_OPERATOR_FINDINGS")
        text = File.read!(findings_path)
        catalog = Contract.live_catalog!(@root, manifest_path, text)
        # Exercise the selected path independently of neighboring canonical manifests.
        scratch =
          Path.join(
            Path.dirname(Path.dirname(manifest_path)),
            "contract_selected_#{System.unique_integer([:positive])}"
          )

        File.cp_r!(Path.dirname(manifest_path), scratch)
        selected = Path.join(scratch, "selected-evidence.json")
        bytes = File.read!(manifest_path)

        try do
          File.write!(selected, bytes)
          assert Contract.live_catalog!(@root, selected, "bundle_path: #{scratch}") != %{}
          original = Jason.decode!(bytes)

          for bad <- [
                Map.put(original, "baseSha", "forged"),
                put_in(original, ["captures", Access.at(0), "outputSha256"], "forged"),
                put_in(original, ["captures", Access.at(0), "outputPath"], "missing-output.png")
              ] do
            File.write!(selected, Jason.encode!(bad, pretty: true) <> "\n")

            assert_raise ArgumentError, ~r/live source\/asset\/output custody failed/, fn ->
              Contract.live_catalog!(@root, selected, "bundle_path: #{scratch}")
            end
          end
        after
          File.rm_rf!(scratch)
        end

        rows = Contract.findings(text)
        assert Contract.finding_errors(rows, Contract.ids(inventory()), catalog) == []

        for row <- rows, String.starts_with?(row["evidence"], "source:") do
          path = String.replace_prefix(row["evidence"], "source:", "")

          assert Enum.any?(checklist()["items"], fn item ->
                   item["id"] == row["id"] and Enum.any?(item["anchors"], &(&1["path"] == path))
                 end)
        end

        if System.get_env("THREADLINE_OPERATOR_PREVIEW_REQUIRED") == "1" do
          receipt_path = Contract.required_path!("THREADLINE_OPERATOR_PREVIEW_RECEIPT")
          receipt = Jason.decode!(File.read!(receipt_path))
          manifest = Jason.decode!(File.read!(manifest_path))
          assert Contract.preview_errors(receipt, manifest, @root) == []
          assert Contract.verify_preview!(@root, receipt_path) == "preview verified"

          assert {_, 0} =
                   System.cmd("kill", ["-0", to_string(receipt["pid"])], stderr_to_stdout: true)

          assert {listeners, 0} =
                   System.cmd(
                     "lsof",
                     [
                       "-nP",
                       "-a",
                       "-p",
                       to_string(receipt["pid"]),
                       "-iTCP:#{URI.parse(receipt["url"]).port}",
                       "-sTCP:LISTEN"
                     ],
                     stderr_to_stdout: true
                   )

          assert listeners =~ "127.0.0.1:#{URI.parse(receipt["url"]).port}"
          refute listeners =~ "*:"

          assert {"200", 0} =
                   System.cmd("curl", [
                     "--max-time",
                     "5",
                     "-s",
                     "-o",
                     "/dev/null",
                     "-w",
                     "%{http_code}",
                     receipt["url"] <> "/users/log_in"
                   ])
        end

      other ->
        flunk("Unknown operator evidence mode #{inspect(other)}")
    end
  end
end
