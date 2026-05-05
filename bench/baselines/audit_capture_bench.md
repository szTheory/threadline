Benchmark

Benchmark run from 2026-05-05 16:40:30.222131Z UTC

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
    <td style="white-space: nowrap">delete</td>
    <td style="white-space: nowrap; text-align: right">10.85 K</td>
    <td style="white-space: nowrap; text-align: right">92.19 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;36.57%</td>
    <td style="white-space: nowrap; text-align: right">89.38 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">213.17 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">insert</td>
    <td style="white-space: nowrap; text-align: right">5.14 K</td>
    <td style="white-space: nowrap; text-align: right">194.69 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;44.81%</td>
    <td style="white-space: nowrap; text-align: right">174.67 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">485.59 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">update</td>
    <td style="white-space: nowrap; text-align: right">4.40 K</td>
    <td style="white-space: nowrap; text-align: right">227.14 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;30.37%</td>
    <td style="white-space: nowrap; text-align: right">210.54 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">508.27 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">delete</td>
    <td style="white-space: nowrap;text-align: right">10.85 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">insert</td>
    <td style="white-space: nowrap; text-align: right">5.14 K</td>
    <td style="white-space: nowrap; text-align: right">2.11x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">update</td>
    <td style="white-space: nowrap; text-align: right">4.40 K</td>
    <td style="white-space: nowrap; text-align: right">2.46x</td>
  </tr>

</table>