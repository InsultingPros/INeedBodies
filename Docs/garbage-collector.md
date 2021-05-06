# Removed code

This was commented anyways, so..

```java
simulated function PlayDyingAnimation(class<DamageType> DamageType, vector HitLoc)
{
  local vector shotDir, hitLocRel, deathAngVel, shotStrength;
  local float maxDim;
  local string RagSkelName;
  local KarmaParamsSkel skelParams;
  local bool PlayersRagdoll;
  local PlayerController pc;

  if( MyExtCollision!=None )
    MyExtCollision.Destroy();
  if ( Level.NetMode != NM_DedicatedServer )
  {
    // Is this the local player's ragdoll?
    if(OldController != None)
      pc = PlayerController(OldController);
    if( pc != None && pc.ViewTarget == self )
      PlayersRagdoll = true;

    // In low physics detail, if we were not just controlling this pawn,
    // and it has not been rendered in 3 seconds, just destroy it.

    if( Level.NetMode == NM_ListenServer )
        {
        // For a listen server, use LastSeenOrRelevantTime instead of render time so
            // monsters don't disappear for other players that the host can't see - Ramm
            if( Level.PhysicsDetailLevel != PDL_High && !PlayersRagdoll && (Level.TimeSeconds-LastSeenOrRelevantTime)>3 ||
                bGibbed )
            {
          //Destroy();
          return;
            }
        }
    else if( Level.PhysicsDetailLevel!=PDL_High && !PlayersRagdoll && (Level.TimeSeconds-LastRenderTime)>3 ||
            bGibbed )
    {
      //Destroy();
      return;
    }

    // Try and obtain a rag-doll setup. Use optional 'override' one out of player record first, then use the species one.
    if( RagdollOverride != "")
      RagSkelName = RagdollOverride;
    else if(Species != None)
      RagSkelName = Species.static.GetRagSkelName( GetMeshName() );
    else RagSkelName = "Male1"; // Otherwise assume it is Male1 ragdoll were after here.

    KMakeRagdollAvailable();

    if( KIsRagdollAvailable() && RagSkelName != "" )
    {
      skelParams = KarmaParamsSkel(KParams);
      skelParams.KSkeleton = RagSkelName;

      // Stop animation playing.
      StopAnimating(true);

      if( DamageType != None )
      {
        if ( DamageType.default.bLeaveBodyEffect )
          TearOffMomentum = vect(0,0,0);

        if( DamageType.default.bKUseOwnDeathVel )
        {
          RagDeathVel = DamageType.default.KDeathVel;
          RagDeathUpKick = DamageType.default.KDeathUpKick;
          RagShootStrength = DamageType.default.KDamageImpulse;
        }
      }

      // Set the dude moving in direction he was shot in general
      shotDir = Normal(GetTearOffMomemtum());
      shotStrength = RagDeathVel * shotDir;

      // Calculate angular velocity to impart, based on shot location.
      hitLocRel = TakeHitLocation - Location;

      if( DamageType.default.bLocationalHit )
      {
        hitLocRel.X *= RagSpinScale;
        hitLocRel.Y *= RagSpinScale;

        if( Abs(hitLocRel.X)  > RagMaxSpinAmount )
        {
          if( hitLocRel.X < 0 )
          {
            hitLocRel.X = FMax((hitLocRel.X * RagSpinScale), (RagMaxSpinAmount * -1));
          }
          else
          {
            hitLocRel.X = FMin((hitLocRel.X * RagSpinScale), RagMaxSpinAmount);
          }
        }

        if( Abs(hitLocRel.Y)  > RagMaxSpinAmount )
        {
          if( hitLocRel.Y < 0 )
          {
            hitLocRel.Y = FMax((hitLocRel.Y * RagSpinScale), (RagMaxSpinAmount * -1));
          }
          else
          {
            hitLocRel.Y = FMin((hitLocRel.Y * RagSpinScale), RagMaxSpinAmount);
          }
        }

      }
      else
      {
          // We scale the hit location out sideways a bit, to get more spin around Z.
          hitLocRel.X *= RagSpinScale;
          hitLocRel.Y *= RagSpinScale;
      }

      //log("hitLocRel.X = "$hitLocRel.X$" hitLocRel.Y = "$hitLocRel.Y);
      //log("TearOffMomentum = "$VSize(GetTearOffMomemtum()));

      // If the tear off momentum was very small for some reason, make up some angular velocity for the pawn
      if( VSize(GetTearOffMomemtum()) < 0.01 )
      {
        //Log("TearOffMomentum magnitude of Zero");
        deathAngVel = VRand() * 18000.0;
      }
      else
      {
        deathAngVel = RagInvInertia * (hitLocRel cross shotStrength);
      }

      // Set initial angular and linear velocity for ragdoll.
      // Scale horizontal velocity for characters - they run really fast!
      if ( DamageType.Default.bRubbery )
        skelParams.KStartLinVel = vect(0,0,0);
      if ( Damagetype.default.bKUseTearOffMomentum )
        skelParams.KStartLinVel = GetTearOffMomemtum() + Velocity;
      else
      {
        skelParams.KStartLinVel.X = 0.6 * Velocity.X;
        skelParams.KStartLinVel.Y = 0.6 * Velocity.Y;
        skelParams.KStartLinVel.Z = 1.0 * Velocity.Z;
        skelParams.KStartLinVel += shotStrength;
      }
      // If not moving downwards - give extra upward kick
      if( !DamageType.default.bLeaveBodyEffect && !DamageType.Default.bRubbery && (Velocity.Z > -10) )
        skelParams.KStartLinVel.Z += RagDeathUpKick;

      if ( DamageType.Default.bRubbery )
      {
        Velocity = vect(0,0,0);
        skelParams.KStartAngVel = vect(0,0,0);
      }
      else
      {
        skelParams.KStartAngVel = deathAngVel;

        // Set up deferred shot-bone impulse
        maxDim = Max(CollisionRadius, CollisionHeight);

        skelParams.KShotStart = TakeHitLocation - (1 * shotDir);
        skelParams.KShotEnd = TakeHitLocation + (2*maxDim*shotDir);
        skelParams.KShotStrength = RagShootStrength;
      }

      //log("RagDeathVel = "$RagDeathVel$" KShotStrength = "$skelParams.KShotStrength$" RagDeathUpKick = "$RagDeathUpKick);

      // If this damage type causes convulsions, turn them on here.
      if(DamageType != None && DamageType.default.bCauseConvulsions)
      {
        RagConvulseMaterial=DamageType.default.DamageOverlayMaterial;
        skelParams.bKDoConvulsions = true;
      }

      // Turn on Karma collision for ragdoll.
      KSetBlockKarma(true);

      // Set physics mode to ragdoll.
      // This doesn't actaully start it straight away, it's deferred to the first tick.
      SetPhysics(PHYS_KarmaRagdoll);

      // If viewing this ragdoll, set the flag to indicate that it is 'important'
      if( PlayersRagdoll )
        skelParams.bKImportantRagdoll = true;

      skelParams.bRubbery = DamageType.Default.bRubbery;
      bRubbery = DamageType.Default.bRubbery;

      skelParams.KActorGravScale = RagGravScale;

      return;
    }
    // jag
  }
  // non-ragdoll death fallback
  Velocity += GetTearOffMomemtum();
  BaseEyeHeight = Default.BaseEyeHeight;
  SetTwistLook(0, 0);
  SetInvisibility(0.0);
  // We don't do this - Ramm
  //PlayDirectionalDeath(HitLoc);
  SetPhysics(PHYS_Falling);
}
```
