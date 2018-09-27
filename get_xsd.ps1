if(-not $global:UcmdbUser){
    $global:UcmdbUser = Get-Credential
}
$bb = "https://itsomi.tools.cihs.gov.on.ca/axis2/services/UcmdbService"
$uri = "$($bb)?wsdl"
Write-Host $uri
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
Invoke-WebRequest -Uri $uri -OutFile "UcmdbService.wsdl" -Credential $UcmdbUser
$uri = "$($bb)?xsd"
Invoke-WebRequest -Uri "$uri" -OutFile "UcmdbService.xsd" -Credential $UcmdbUser
(Get-Content "UcmdbService.wsdl") -replace '"UcmdbService\?xsd=xsd(\d+)"', '"UcmdbService.xsd$1"' | Out-File "UcmdbService.wsdl" -Encoding ASCII
(Get-Content "UcmdbService.wsdl") -replace '"UcmdbService\?xsd"', '"UcmdbService.xsd"' | Out-File "UcmdbService.wsdl" -Encoding ASCII
(Get-Content "UcmdbService.xsd") -replace '"UcmdbService\?xsd=xsd(\d+)"', '"UcmdbService.xsd$1"' | Out-File "UcmdbService.xsd" -Encoding ASCII
for ($i=0; $i -le 27; $i++)
{
    $uri = "$($bb)?xsd=xsd$($i)"
    Invoke-WebRequest -Uri $uri -OutFile "UcmdbService.xsd$i" -Credential $UcmdbUser
    (Get-Content "UcmdbService.xsd$i") -replace '"UcmdbService\?xsd=xsd(\d+)"', '"UcmdbService.xsd$1"' | Out-File "UcmdbService.xsd$i" -Encoding ASCII
}