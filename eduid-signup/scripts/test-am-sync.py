#!/opt/eduid/bin/python

from eduid_am.celery import celery
from eduid_am.tasks import update_attributes_keep_result

broker_url = 'amqp://eduid:eduid_pw@rabbitmq.docker/am'
celery.conf.update({'BROKER_URL': broker_url,
                    'CELERY_TASK_SERIALIZER': 'json',
                    })

rtask = update_attributes_keep_result.delay('eduid_signup', 'NOT_A_REAL_USER')

print("RTask: {!r}".format(rtask))

#help(rtask)

result = rtask.get(timeout=3)
print("Result: {!r}".format(result))



