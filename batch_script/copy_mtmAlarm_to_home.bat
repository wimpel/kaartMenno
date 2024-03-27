:: GEBRUIK:
:: 1. zet dit batch bestaand ergens op de U-schijf
:: 2. open ene citrix sessie
:: 3. open een command prompt naar de locatie
:: 4. run het batch bestand
:: 5. dit kopieert (in een citrix-sessie) bestanden van de dvm-proxy naar een lokale omgeving
::
:: ieder jaar moet het jaartal worden aangepast!!!
::
robocopy \\ad.rws.nl\p-dfs01\appsdata\DVMData\hist\mtm\mn\storinglijst\2024  \\Client\I$\brondata\mtm-alarm\dvm-proxy\mn\storinglijst\2024 *openstaandestoringen.txt /S /XO /FFT
robocopy \\ad.rws.nl\p-dfs01\appsdata\DVMData\hist\mtm\non\storinglijst\2024  \\Client\I$\brondata\mtm-alarm\dvm-proxy\non\storinglijst\2024 *openstaandestoringen.txt /S /XO /FFT
robocopy \\ad.rws.nl\p-dfs01\appsdata\DVMData\hist\mtm\nwn\storinglijst\2024  \\Client\I$\brondata\mtm-alarm\dvm-proxy\nwn\storinglijst\2024 *openstaandestoringen.txt /S /XO /FFT
robocopy \\ad.rws.nl\p-dfs01\appsdata\DVMData\hist\mtm\zn\storinglijst\2024  \\Client\I$\brondata\mtm-alarm\dvm-proxy\zn\storinglijst\2024 *openstaandestoringen.txt /S /XO /FFT
robocopy \\ad.rws.nl\p-dfs01\appsdata\DVMData\hist\mtm\zwn\storinglijst\2024  \\Client\I$\brondata\mtm-alarm\dvm-proxy\zwn\storinglijst\2024 *openstaandestoringen.txt /S /XO /FFT
::robocopy \\ad.rws.nl\p-dfs01\appsdata\DVMData\hist\mtm  \\Client\I$\brondata\mtm-alarm\dvm-proxy *openstaandestoringen.txt /S /XO /FFT
::