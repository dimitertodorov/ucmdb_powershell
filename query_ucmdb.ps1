if(-not $global:UcmdbUser){
    $global:UcmdbUser = Get-Credential
}
$endpoint = "https://itsomi.tools.cihs.gov.on.ca/axis2/services/UcmdbService"
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }
[ServerCertificateValidationCallback]::Ignore()
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
#Query CIs by Type
[xml]$Response = Invoke-WebRequest -Uri $endpoint -Method Post -ContentType "application/soap+xml;charset=UTF-8;action=`"getCIsByType`"" -Credential $UcmdbUser -InFile "$PSScriptRoot\requests\query_cis_by_type.xml"
$ChunksInfo = $Response.Envelope.Body.getCIsByTypeResponse.chunkInfo

[xml]$global:ChunksRequest = Get-Content  "$PSScriptRoot\requests\pull_chunks.xml"
$ChunksRequest.Envelope.Body.pullTopologyMapChunks.ChunkRequest.chunkInfo.numberOfChunks = "$($ChunksInfo.numberOfChunks)"
$ChunksRequest.Envelope.Body.pullTopologyMapChunks.ChunkRequest.chunkInfo.chunksKey.key1 = "$($ChunksInfo.chunksKey.key1)"
$ChunksRequest.Envelope.Body.pullTopologyMapChunks.ChunkRequest.chunkInfo.chunksKey.key2 = "$($ChunksInfo.chunksKey.key2)"
[xml]$global:OutDocument = New-Object System.Xml.XmlDocument
#Empty XML for Outputting the Nodes:
for ($i=1; $i -le $ChunksInfo.numberOfChunks; $i++)
{
    $ChunksRequest.Envelope.Body.pullTopologyMapChunks.ChunkRequest.chunkNumber = "$i"
    [xml]$Response = Invoke-WebRequest -Uri $endpoint -Method Post -ContentType "application/soap+xml;charset=UTF-8;action=`"pullChunkResult`"" -Credential $UcmdbUser -Body $ChunksRequest.OuterXml
    Write-Host "Pulled in $($Response.Envelope.Body.pullTopologyMapChunksResponse.topologyMap.CINodes.CINode.CIs.CI.Count) CIS for Chunk $i"
    # foreach($node_ci in $Response.Envelope.Body.pullTopologyMapChunksResponse.topologyMap.CINodes.CINode.CIs.CI){
    #     if($OutDocument.DocumentElement -eq $null){
    #         $OutDocument.AppendChild($OutDocument.ImportNode($node_ci,$true))
    #     }else{
    #         $OutDocument.DocumentElement.AppendChild($OutDocument.ImportNode($node_ci,$true))
    #     }
    # }
}