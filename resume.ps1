

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

ruby down.rb
