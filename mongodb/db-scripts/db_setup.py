#!/usr/bin/env python

from __future__ import absolute_import

import argparse
import yaml
from pymongo import MongoClient
from pymongo.errors import OperationFailure

##
## Reads users and collections from a yaml file.
##
## User passwords will be set to [username]_pw.
##

def create_users(client, databases):
    for db_name, conf in databases.items():
        print('Adding users for {}'.format(db_name))
        access_conf = conf.get('access', dict())
        for root_user in access_conf.get('root', list()):
            print('Added root user: {}'.format(root_user))
            client[db_name].add_user(root_user, '{}_pw'.format(root_user), roles=["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"])
        for rw_user in access_conf.get('readWrite', list()):
            print('Added rw user: {}'.format(rw_user))
            client[db_name].add_user(rw_user, '{}_pw'.format(rw_user), roles=[{'role':'readWrite', 'db': db_name}])
        for ro_user in access_conf.get('read', list()):
            print('Added ro user: {}'.format(ro_user))
            client[db_name].add_user(ro_user, '{}_pw'.format(ro_user), roles=[{'role':'read', 'db': db_name}])
        print('---')

def init_collections(client, databases):
    for db_name, conf in databases.items():
        print('Init collections for {}'.format(db_name))
        collections = conf.get('collections', list())
        for collection in collections:
            doc = client[db_name][collection].insert({'init': True})
            client[db_name][collection].remove(doc)
            print('Created {}'.format(collection))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--file', help="YAML file (/opt/eduid/db-scripts/local.yaml)", type=str, default="/opt/eduid/db-scripts/local.yaml")
    parser.add_argument('-d', '--database', help="Mongo database adress (localhost)", type=str, default="localhost")
    parser.add_argument('-r', '--replset', help="Name of replica set", type=str, default=None)
    args = parser.parse_args()

    with open(args.file) as f:
        data = yaml.safe_load(f)

    try:
        # opportunistic replica set initialization, this will fail
        # if the db is not started as a replica set or if the
        # replica set is already initialized
        client = MongoClient(args.database)
        client.admin.command("replSetInitiate")
    except OperationFailure:
        pass
    finally:
        client.close()

    if args.replset is not None:
        client = MongoClient(args.database, replicaset=args.replset)
    else:
        client = MongoClient(args.database)

    databases = data['mongo_databases']
    create_users(client, databases)
    init_collections(client, databases)

if __name__ == "__main__":
    main()

