-- tady nastavíme čísla důležitých polí v tsv souboru z OBD
-- je třeba nejdřív do ní doplnit body z RIV
--

local config = {}

-- čísla polí je možné vypsat pomocí příkazu
-- csvcut -n -t jmeno_tsv_souboru
config.pole = {
  body = 3,
  autori = 21,
  riv = 1,
  id = 2,
  nazev = 14,
  rok = 10,
}

-- znak, kterým jsou oddělení jednotliví autoři
config.delimiter = "|"

config.author_pattern = "^([^%(]+)%(([^%)]+)%).-vyk%. fak%.%: (PedF%/[^%]]+)"


return config

