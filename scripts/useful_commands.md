## Pulmap 

1. Clear out solr

	```
	curl http://<solrserver>:8983/solr/pulmap/update?commit=true -H "Content-Type: text/xml" --data-binary '<delete><query>*:*</query></delete>'
	```


## Opal

1. Clear out solr

	```
	curl http://127.0.0.1:8983/solr/opal/update?commit=true -H "Content-Type: text/xml" --data-binary '<delete><query>*:*</query></delete>'
	```