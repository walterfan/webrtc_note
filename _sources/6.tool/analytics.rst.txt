#################
Data Analytics
#################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ ==========================
**Abstract** Data Analytics
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ ==========================



.. contents::
   :local:

Overview
====================
There are two kinds of data for data analytics:

1. Log
2. Metrics

The requirement is 

1. stable - high availablity
2. quick - from source to destination
3. keep long time/large capacity
4. easy to learn
5. provide API
6. rich analytics and visualize tool


ELK + K
--------------------
ElasticSearch + LogStash + Kibana + Kafka

Data flow::

    LogStash -> Kafka -> ElasticSearch -> Kibana



FIG + K
--------------------

Data flow::

    Filebeat -> Kafka -> InfluxDB -> Grafana



Pinot
---------------------
Pinot is a real-time distributed OLAP datastore, purpose-built to provide ultra low-latency analytics, even at extremely high throughput. It can ingest directly from streaming data sources - such as Apache Kafka and Amazon Kinesis - and make the events available for querying instantly. It can also ingest from batch data sources such as Hadoop HDFS, Amazon S3, Azure ADLS, and Google Cloud Storage.

At the heart of the system is a columnar store, with several smart indexing and pre-aggregation techniques for low latency. This makes Pinot the most perfect fit for user-facing realtime analytics. At the same time, Pinot is also a great choice for other analytical use-cases, such as internal dashboards, anomaly detection, and ad-hoc data exploration.


Iceberg
---------------------
Iceberg is a high-performance format for huge analytic tables. Iceberg brings the reliability and simplicity of SQL tables to big data, while making it possible for engines like Spark, Trino, Flink, Presto, and Hive to safely work with the same tables, at the same time.