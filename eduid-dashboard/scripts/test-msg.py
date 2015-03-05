#!/opt/eduid/bin/python

import eduiddashboard

settings = {'msg_broker_url': 'amqp://eduid:eduid_pw@rabbitmq.docker/msg'}

msgrelay = eduiddashboard.msgrelay.MsgRelay(settings)

print("MsgRelay: {!r}".format(msgrelay))

#help(msgrelay)
#sys.exit(0)

print(msgrelay.get_postal_address('190001019876'))
print()

print(msgrelay.get_relations_to('190001019876', '20001019876'))
print()
