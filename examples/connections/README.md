# Manage connections

Connections allows you manage who can interact with your app. Even your app is intended to interact with everybody, just you or a selected group of users, you can manage connections with three methods `permit_connection`, `revoke_connection` and `allowed_connections`.

## Running this example

In order to run this example, you must have a valid app keypair. Self-keypairs are issued by [Self Developer portal](https://developer.selfid.net/) when you create a new app.

Once you have your valid `SELF_APP_ID` and `SELF_APP_DEVICE_SECRET` you can run this example with:

```bash
$ SELF_APP_ID=XXXXX SELF_APP_DEVICE_SECRET=XXXXXXXX ruby app.rb <your_self_id>
```

