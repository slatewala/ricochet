---
title: "Ricochet - Geometry Puzzles Disguised As An Arcade Shooter"
date: 2026-04-26
categories:
  - Games
  - Mobile
tags:
  - flutter
  - puzzle
  - geometry
  - arcade
  - android
excerpt: "Aim a green beam. Bounce off walls. Hit the red dot. Easy until the bounce limit drops to one."
featured_image: /assets/games/ricochet-feature.png
---

## A Tiny Geometry Engine In Your Pocket

**Ricochet** is what happens when you take the most satisfying part of pool, snooker, and laser tag and strip away everything else. You aim a beam from the bottom of the screen toward a red target somewhere above. The beam reflects off the screen edges. Every reflection costs you a bounce from your budget.

Easy levels give you four bounces. Brutal ones give you one. Suddenly the casual flick becomes a careful angle calculation done entirely with your eyes.

## Why Bounded Reflection Is Brain Candy

Humans are absurdly good at spatial trajectory prediction - it is what kept our ancestors from being eaten by anything that moved faster than them. Ricochet plugs straight into that primal subsystem.

The catch is that when you constrain the bounce count, the obvious path stops working. You have to picture the mirror trick - where the target would appear if walls were transparent. Once that mental flip clicks, levels you thought were impossible become trivial. That moment of insight is the dopamine hit the entire game is built around.

## The Code

The whole game is a `CustomPainter` plus a tiny physics loop. Step the laser by twelve sub-steps per frame to avoid wall-tunneling. On each step, check screen edges for reflection, check distance to the target for a hit. Decrement bounce count on each wall, end the run if it hits zero.

No pathfinding, no AI, no level designer. The random target plus random bounce limit produces hundreds of unique puzzles for free.

## Try It

Source, custom icon, sound effect, release APK on GitHub. Sideload, find your favorite angle, then watch yourself second-guess it.
