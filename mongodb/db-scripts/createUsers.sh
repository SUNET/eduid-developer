#!/bin/bash
#
# Create users for the eduID local developer environment.
#

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
for db in eduid_signup eduid_dashboard eduid_api; do
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
for db in eduid_idp eduid_idp_authninfo eduid_idp_pysaml2 eduid_actions; do
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

#
# User eduid_actions, readWrite
#
for db in eduid_tou; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_actions"}) == 0) {
         db.addUser( { user: "eduid_actions", pwd: "eduid_actions_pw", roles: ["readWrite"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_api, readWrite
#
for db in eduid_api; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_api"}) == 0) {
         db.addUser( { user: "eduid_api", pwd: "eduid_api_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_api, read
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_api"}) == 0) {
         db.addUser( { user: "eduid_api", pwd: "eduid_api_pw", roles: ["read"] } );
      }
'
done

# -------------------------------------------------------------------------------------
#
# User eduid_lookup_mobile, readWrite
#
for db in eduid_lookup_mobile; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_lookup_mobile"}) == 0) {
         db.addUser( { user: "eduid_lookup_mobile", pwd: "eduid_lookup_mobile_pw", roles: ["readWrite"] } );
      }
'
done


# -------------------------------------------------------------------------------------
#
# User eduid_actions, readWrite
#
for db in eduid_actions; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_actions"}) == 0) {
         db.addUser( { user: "eduid_actions", pwd: "eduid_actions_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_am, readWrite
#
for db in eduid_actions; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_am"}) == 0) {
         db.addUser( { user: "eduid_am", pwd: "eduid_am_pw", roles: ["readWrite"] } );
      }
'
done

#
# User eduid_actions, read
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_actions"}) == 0) {
         db.addUser( { user: "eduid_actions", pwd: "eduid_actions_pw", roles: ["read"] } );
      }
'
done

#
# User eduid_idproofing_letter, read
#
for db in eduid_am; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_idproofing_letter"}) == 0) {
         db.addUser( { user: "eduid_idproofing_letter", pwd: "eduid_idproofing_letter_pw", roles: ["read"] } );
      }
'
done

#
# User eduid_idproofing_letter, readWrite
#
for db in eduid_idproofing_letter; do
    mongo localhost/${db} --eval '
      if (db.system.users.count({"user": "eduid_idproofing_letter"}) == 0) {
         db.addUser( { user: "eduid_idproofing_letter", pwd: "eduid_idproofing_letter_pw", roles: ["readWrite"] } );
      }
'
done


