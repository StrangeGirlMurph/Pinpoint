---
description: General instructions
applyTo: '**' 
---

# What this project is

This flutter app is a cross-plattform app to map things. 

The basic workflow is as follows: 
1. the user finds something outside
2. they add an entry/marker for that with one of these options:
  - directly at their GPS location
  - directly at their GPS location by taking a picture
  - by selecting a picture from their device with a GPS location in the metadata
  - by long pressing on the map where it is supposed to be
3. they can add more information to every entry like a picture, a description, a time (defaults to creation time)

The entries are grouped. There is a page with the map which shows the entries of the group selected from a dropdown. The markers there can be manually moved and the corresponding entries edited with a bottom sheet that pops up when tapping the marker. There is a page that provides a list view of the entries with the same dropdown menu and filtering as the map page. The list view also shows entries without a location and allows to add such entries. There is a page to manage the groups/lists. There lists can be added, deleted, reordered and so on. The settings page contains the settings and then there is a page for explanations and a page with a text to support me.

# How to help me

With all design choices that come up I always need to be the one making decisions. You are there to help me make informed decisions. Tell me about the options, their pros and cons and then let me choose. Only then you can implement something. Don't go off just doing something! I am the boss. Ask me when you're unsure.

Only generate reviewable chunks of code at a time. Always focus on the basics and simple code! I can fill in the details manually later on or customize things to my likings.

Always check documentation online before adding something new!

Don't leave comments in the code to highlight your work. Only use comments to explain complex pieces of code.