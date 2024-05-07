copy categories 
from 's3://<<nome_csv>>..csv' 
CREDENTIALS 'aws_access_key_id=<<id_aws>>,aws_secret_access_key=<<key>>' 
delimiter ';' 
region '<<regiao>>'
IGNOREHEADER 1
DATEFORMAT AS 'YYYY-MM-DD HH:MI:SS'
removequotes;
