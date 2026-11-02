# Teams

Standard and Pro plans include a Team feature that lets you share your plan
with your team. Everyone you add builds your apps under your plan, each with
their own sign-in, so nobody shares a key.

## Set it up

1. **Create the team.** On dartpub.dev, open
   [Settings → Team](https://dartpub.dev/settings/team), give the team a
   short name and select **Create team**.
2. **Add members** by their GitHub username: up to 3 people on Standard, you
   included, and any number on Pro. Each person signs in once first, on
   dartpub.dev or with `dn login`, and builds with their own `dn login`.
   They don't need a plan of their own.
3. **Name the team in the project's `pubspec.yaml`,** and commit it:

   ```yaml
   dartnative:
     team: AcmeCorp
   ```

Every build of that project, by you or any member, then uses your plan.
Their other projects stay on their own plan.

## CodePush

Members can build the team's apps. A CodePush fix changes your app on every
phone that has it, at once, so only you and the members you allow can make
a release, send a fix or take one back. Allow a member, or take it back, in
Settings → Team.

## From CI

A CI job signs in as a person, never with a shared key. You or a member
create an **Apps (builds and CodePush)** token in
[Settings → API](https://dartpub.dev/settings/api) and store it in the CI's
secrets as `DN_PUBLISH_TOKEN`. The job then builds as that person: it counts
as them, not as one more member, and it can make a release or send a fix only
while they are allowed to. The email for each fix names who sent it.

## When someone leaves

Remove them in Settings → Team, or they leave on their own. From then on
their builds no longer get the team's plan, and they can't send or take back a
fix, with any CI token they created. Nothing else changes: there is no key to
replace, nobody else has to do anything, and your published apps keep
working. If your CI used their token, create a new one.
