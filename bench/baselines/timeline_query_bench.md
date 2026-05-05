Benchmark

Benchmark run from 2026-05-05 16:40:38.069299Z UTC

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
    <td style="white-space: nowrap">timeline_by_table</td>
    <td style="white-space: nowrap; text-align: right">148.16</td>
    <td style="white-space: nowrap; text-align: right">6.75 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;70.80%</td>
    <td style="white-space: nowrap; text-align: right">5.63 ms</td>
    <td style="white-space: nowrap; text-align: right">36.37 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">timeline_unfiltered</td>
    <td style="white-space: nowrap; text-align: right">1.26</td>
    <td style="white-space: nowrap; text-align: right">794.48 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;16.66%</td>
    <td style="white-space: nowrap; text-align: right">827.92 ms</td>
    <td style="white-space: nowrap; text-align: right">906.90 ms</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">timeline_by_table</td>
    <td style="white-space: nowrap;text-align: right">148.16</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">timeline_unfiltered</td>
    <td style="white-space: nowrap; text-align: right">1.26</td>
    <td style="white-space: nowrap; text-align: right">117.71x</td>
  </tr>

</table>