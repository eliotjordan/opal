## Pulmap 

1. Clear out solr

	```
	$ curl http://<solrserver>:8983/solr/pulmap/update?commit=true -H "Content-Type: text/xml" --data-binary '<delete><query>*:*</query></delete>'
	```


## Opal

1. Clear out solr

	```
	$ curl http://127.0.0.1:8983/solr/opal/update?commit=true -H "Content-Type: text/xml" --data-binary '<delete><query>*:*</query></delete>'
	```

## Fedora

1. Wipe all data

	```
	$ sudo service tomcat7 stop
	$ rm -r /mnt/fedora/*
	$ sudo service tomcat7 start

	```

## Sidekiq

1. Control workers

	```
	$ sudo initctl status 'opal-workers'
	$ sudo initctl stop 'opal-workers'
	$ sudo initctl start 'opal-workers'

	```

1. Reset statistics

	```
	$ sudo su deploy
	$ RAILS_ENV=production bundle exec rails c
	$ Sidekiq::Stats.new.reset

	```

1. Ingest works from json document

	```
	$ sudo su deploy
	$ RAILS_ENV=production bundle exec rake ingest_datasets scripts/metadata.json

	```