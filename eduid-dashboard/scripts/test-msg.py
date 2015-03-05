#!/opt/eduid/bin/python

import eduiddashboard

settings = {'msg_broker_url': 'amqp://eduid:eduid_pw@rabbitmq.docker/msg'}

msgrelay = eduiddashboard.msgrelay.MsgRelay(settings)

print("MsgRelay: {!r}".format(msgrelay))

#help(msgrelay)
#sys.exit(0)

print(msgrelay.get_postal_address('190001019876'))
print()

for nin in ['200202025678', '197512125432', '195010106543']:
    print("Relations to {!r}:".format(nin))
    print(msgrelay.get_relations_to('190001019876', nin))
    print()
