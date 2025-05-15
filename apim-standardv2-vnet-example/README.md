# apim-standardv2-vnet-example

API ManagementのStandard v2で送受信両方をVNetに閉じ込められるか検証する  

送信はVNet統合でできるはず  
https://learn.microsoft.com/ja-jp/azure/api-management/integrate-vnet-outbound  

受信はプライベートエンドポイントでいけそう  
https://learn.microsoft.com/ja-jp/azure/api-management/private-endpoint?tabs=classic  

```bash
az deployment group create -g $rgName -f ./apim-standardv2-vnet-example/main.bicep
```