# Zero knowledge information request

A zero knowledge information request allows you do assertions on user's facts through _Self Intermediary_ without direct access to user's information. 

This prevents users to leak sensible information with untrusted peers and keep the trust on the platform.

## Running this example

In order to run this example, you must have a valid app keypair. Self-keypairs are issued by [Self Developer portal](https://developer.selfid.net/) when you create a new app.

Once you have your valid `SELF_APP_ID` and `SELF_APP_SECRET` you can run this example with:

```bash
$ SELF_INTERMEDIARY=XXXX SELF_APP_ID=XXXXX SELF_APP_SECRET=XXXXXXXX ruby app.rb
```

## Process diagram

This diagram shows how does zero knowledge information request process works internally.

![Diagram](diagram.png)

1. Request zero knowledge information through the self SDK with the data you want to attest like age > 18.
2. SDK will send an information request to the intermediary.
3. Intermediary will send an information request with the same facts you want to attest to your already connected user.
4. The user will select the requested facts and accept sharing them with the intermediary.
5. The user’s device will send back a signed response with requested facts.
6. Intermediary verifies the response has been signed by the user based on its public keys.
7. Intermediary verifies each fact is signed by the user/app specified on each fact.
8. Intermediary does its calculations and signs specific facts with the result, and it sends it back to your app.
9. SDK on your app verifies the response and facts have been signed by the intermediary based on its public keys.
10. Your app gets a verified response with the result of the attestation.
