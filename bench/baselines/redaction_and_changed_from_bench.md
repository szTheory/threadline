Benchmark

Benchmark run from 2026-05-05 16:40:51.363150Z UTC

## System

Benchmark suite executing on the following system:

<table style="width: 1%">
  <tr>
    <th style="width: 1%; white-space: nowrap">Operating System</th>
    <td>macOS</td>
  </tr><tr>
    <th style="white-space: nowrap">CPU Information</th>
    <td style="white-space: nowrap">Apple M2</td>
  </tr><tr>
    <th style="white-space: nowrap">Number of Available Cores</th>
    <td style="white-space: nowrap">8</td>
  </tr><tr>
    <th style="white-space: nowrap">Available Memory</th>
    <td style="white-space: nowrap">16 GB</td>
  </tr><tr>
    <th style="white-space: nowrap">Elixir Version</th>
    <td style="white-space: nowrap">1.19.5</td>
  </tr><tr>
    <th style="white-space: nowrap">Erlang Version</th>
    <td style="white-space: nowrap">28.4.1</td>
  </tr>
</table>

## Configuration

Benchmark suite executing with the following configuration:

<table style="width: 1%">
  <tr>
    <th style="width: 1%">:time</th>
    <td style="white-space: nowrap">2 s</td>
  </tr><tr>
    <th>:parallel</th>
    <td style="white-space: nowrap">1</td>
  </tr><tr>
    <th>:warmup</th>
    <td style="white-space: nowrap">1 s</td>
  </tr>
</table>

## Statistics



Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">update_redacted</td>
    <td style="white-space: nowrap; text-align: right">3.53 K</td>
    <td style="white-space: nowrap; text-align: right">283.13 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;89.15%</td>
    <td style="white-space: nowrap; text-align: right">232.96 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">912.24 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">update_both</td>
    <td style="white-space: nowrap; text-align: right">2.85 K</td>
    <td style="white-space: nowrap; text-align: right">351.39 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;230.59%</td>
    <td style="white-space: nowrap; text-align: right">236.29 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">2027.62 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">update_changed_from</td>
    <td style="white-space: nowrap; text-align: right">2.50 K</td>
    <td style="white-space: nowrap; text-align: right">399.64 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;260.38%</td>
    <td style="white-space: nowrap; text-align: right">261.96 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">2638.32 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">update_baseline</td>
    <td style="white-space: nowrap; text-align: right">1.30 K</td>
    <td style="white-space: nowrap; text-align: right">766.88 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;287.25%</td>
    <td style="white-space: nowrap; text-align: right">317.67 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">11633.22 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">update_redacted</td>
    <td style="white-space: nowrap;text-align: right">3.53 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">update_both</td>
    <td style="white-space: nowrap; text-align: right">2.85 K</td>
    <td style="white-space: nowrap; text-align: right">1.24x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">update_changed_from</td>
    <td style="white-space: nowrap; text-align: right">2.50 K</td>
    <td style="white-space: nowrap; text-align: right">1.41x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">update_baseline</td>
    <td style="white-space: nowrap; text-align: right">1.30 K</td>
    <td style="white-space: nowrap; text-align: right">2.71x</td>
  </tr>

</table>