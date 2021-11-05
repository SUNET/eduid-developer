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
        update = False
        if client[db_name].command('getUser', user) is None:
            print('Adding users for {}'.format(db_name))
        else:
            print('Updating users for {}'.format(db_name))
            update = True
        access_conf = conf.get('access', dict())
        for role, users in access_conf.items():
            print(f'users as {role} in database {db_name}:')
            for user in users:
                if update:
                    client[db_name].command('updateUser', user, pwd=f'{user}_pw', roles=[role])
                else:
                    client[db_name].command('createUser', user, pwd=f'{user}_pw', roles=[role])
                print(f'\t{user}')
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
