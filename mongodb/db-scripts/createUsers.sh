#!/bin/bash

# -------------------------------------------------------------------------------------
#
# User eduid_signup, readWrite
#
for db in eduid_signup; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_signup"}) == 0) {
         db.addUser( { user: "eduid_signup", pwd: "eduid_signup_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_signup, read
#
for db in eduid_tou eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_signup"}) == 0) {
         db.addUser( { user: "eduid_signup", pwd: "eduid_signup_pw", roles: ["read"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_am, readWrite
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_am"}) == 0) {
         db.addUser( { user: "eduid_am", pwd: "eduid_am_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_am, read
#
for db in eduid_signup eduid_dashboard; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_am"}) == 0) {
         db.addUser( { user: "eduid_am", pwd: "eduid_am_pw", roles: ["read"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_dashboard, readWrite
#
for db in eduid_dashboard; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_dashboard"}) == 0) {
         db.addUser( { user: "eduid_dashboard", pwd: "eduid_dashboard_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_dashboard, read
#
for db in eduid_am eduid_idp_authninfo; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_dashboard"}) == 0) {
         db.addUser( { user: "eduid_dashboard", pwd: "eduid_dashboard_pw", roles: ["read"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_idp, readWrite
#
for db in eduid_idp eduid_idp_authninfo eduid_idp_pysaml2; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_idp"}) == 0) {
         db.addUser( { user: "eduid_idp", pwd: "eduid_idp_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_idp, read
#
for db in eduid_am eduid_tou; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_idp"}) == 0) {
         db.addUser( { user: "eduid_idp", pwd: "eduid_idp_pw", roles: ["read"] } );
      }
'
done