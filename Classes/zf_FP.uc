class zf_FP extends Zombiefleshpound_STANDARD
  placeable;


State ZombieDying 
{
ignores AnimEnd, Trigger, Bump, HitWall, HeadVolumeChange, PhysicsVolumeChange, Falling, BreathTimer, Died, RangedAttack;     //Tick

  simulated function Landed(vector HitNormal)
  {
    // SetPhysics(PHYS_None);
    SetCollision(false, false, false);
    // Disable('Tick');
    lifespan=100;
  }

  simulated function Tick(float delta)
  {
    // lifespan=0;
    bcollideworld=true;
    // health=200;
    setcollisionsize(5,5);
  }

  simulated function Timer()
  {
    local KarmaParamsSkel skelParams;

    skelParams = KarmaParamsSkel(KParams);
    skelParams.bKImportantRagdoll = false;
  }

  simulated function BeginState()
  {
    lifespan=0;
    SetTimer(5.0, false);
    SetPhysics(PHYS_Falling);
    if ( Controller != None )
    {
      Controller.Destroy();
    }
  }

  simulated function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex )
  {
    local Vector HitNormal, shotDir;
    local Vector PushLinVel, PushAngVel;
    local Name HitBone;
    local float HitBoneDist;
    local bool bIsHeadshot;
    local vector HitRay;

    if ( bFrozenBody || bRubbery )
      return;

    if( Physics == PHYS_KarmaRagdoll )
    {
      // Can't shoot corpses during de-res
      if ( bDeRes )
        return;

      // Throw the body if its a rocket explosion or shock combo
      if( damageType.Default.bThrowRagdoll )
      {
        shotDir = Normal(Momentum);
        PushLinVel = (RagDeathVel * shotDir) +  vect(0, 0, 250);
        PushAngVel = Normal(shotDir Cross vect(0, 0, 1)) * -18000;
        KSetSkelVel( PushLinVel, PushAngVel );
      }
      else if( damageType.Default.bRagdollBullet )
      {
        if ( Momentum == vect(0,0,0) )
          Momentum = HitLocation - InstigatedBy.Location;
        if ( FRand() < 0.65 )
        {
          if ( Velocity.Z <= 0 )
            PushLinVel = vect(0,0,40);
          PushAngVel = Normal(Normal(Momentum) Cross vect(0, 0, 1)) * -8000 ;
          PushAngVel.X *= 0.5;
          PushAngVel.Y *= 0.5;
          PushAngVel.Z *= 4;
          KSetSkelVel( PushLinVel, PushAngVel );
        }
        PushLinVel = RagShootStrength*Normal(Momentum);
        KAddImpulse(PushLinVel, HitLocation);
        if ( (LifeSpan > 0) && (LifeSpan < DeResTime + 2) )
          LifeSpan += 0.2;
      }
      else
      {
        PushLinVel = RagShootStrength*Normal(Momentum);
        KAddImpulse(PushLinVel, HitLocation);
      }
    }

    if (Damage > 0)
    {
      Health -= Damage;

      if ( !bDecapitated && class<KFWeaponDamageType>(damageType)!=none &&
                class<KFWeaponDamageType>(damageType).default.bCheckForHeadShots )
            {
                bIsHeadShot = IsHeadShot(HitLocation, normal(Momentum), 1.0);
        }

      if( bIsHeadShot )
                RemoveHead();

          HitRay = vect(0,0,0);
          if( InstigatedBy != none )
            HitRay = Normal(HitLocation-(InstigatedBy.Location+(vect(0,0,1)*InstigatedBy.EyeHeight)));

      CalcHitLoc( HitLocation, HitRay, HitBone, HitBoneDist );

      if( InstigatedBy != None )
        HitNormal = Normal( Normal(InstigatedBy.Location-HitLocation) + VRand() * 0.2 + vect(0,0,2.8) );
      else
        HitNormal = Normal( Vect(0,0,1) + VRand() * 0.2 + vect(0,0,2.8) );

            // Actually do blood on a client
            PlayHit(Damage, InstigatedBy, hitLocation, damageType, Momentum);

      DoDamageFX( HitBone, Damage, DamageType, Rotator(HitNormal) );
    }

    if ( (DamageType.Default.DamageOverlayMaterial != None) && (Level.DetailMode != DM_Low) && !Level.bDropDetail )
      SetOverlayMaterial(DamageType.Default.DamageOverlayMaterial, DamageType.default.DamageOverlayTime, true);
  }
}


State Dying
{
ignores AnimEnd, Trigger, Bump, HitWall, HeadVolumeChange, PhysicsVolumeChange, Falling, BreathTimer, Died, RangedAttack;     //Tick

  simulated function Landed(vector HitNormal)
  {
    // SetPhysics(PHYS_None);
    SetCollision(false, false, false);
    // Disable('Tick');
    lifespan=0;
  }

  simulated function Tick(float delta)
  {
    lifespan=0;
  }

  simulated function Timer()
  {
    if ( Controller != None )
    {
      Controller.Destroy();
    }
    StartDeRes();
    Destroy();
  }

  simulated function BeginState()
  {
    lifespan=0;
    SetTimer(120.0, false);
    SetPhysics(PHYS_Falling);
  }

  simulated function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex )
  {
    local Vector HitNormal, shotDir;
    local Vector PushLinVel, PushAngVel;
    local Name HitBone;
    local float HitBoneDist;
    local bool bIsHeadshot;
    local vector HitRay;

    if ( bFrozenBody || bRubbery )
      return;

    if( Physics == PHYS_KarmaRagdoll )
    {
      // Can't shoot corpses during de-res
      if ( bDeRes )
        return;

      // Throw the body if its a rocket explosion or shock combo
      if( damageType.Default.bThrowRagdoll )
      {
        shotDir = Normal(Momentum);
        PushLinVel = (RagDeathVel * shotDir) +  vect(0, 0, 250);
        PushAngVel = Normal(shotDir Cross vect(0, 0, 1)) * -18000;
        KSetSkelVel( PushLinVel, PushAngVel );
      }
      else if( damageType.Default.bRagdollBullet )
      {
        if ( Momentum == vect(0,0,0) )
          Momentum = HitLocation - InstigatedBy.Location;
        if ( FRand() < 0.65 )
        {
          if ( Velocity.Z <= 0 )
            PushLinVel = vect(0,0,40);
          PushAngVel = Normal(Normal(Momentum) Cross vect(0, 0, 1)) * -8000 ;
          PushAngVel.X *= 0.5;
          PushAngVel.Y *= 0.5;
          PushAngVel.Z *= 4;
          KSetSkelVel( PushLinVel, PushAngVel );
        }
        PushLinVel = RagShootStrength*Normal(Momentum);
        KAddImpulse(PushLinVel, HitLocation);
        if ( (LifeSpan > 0) && (LifeSpan < DeResTime + 2) )
          LifeSpan += 0.2;
      }
      else
      {
        PushLinVel = RagShootStrength*Normal(Momentum);
        KAddImpulse(PushLinVel, HitLocation);
      }
    }

    if (Damage > 0)
    {
      Health -= Damage;

      if ( !bDecapitated && class<KFWeaponDamageType>(damageType)!=none &&
                class<KFWeaponDamageType>(damageType).default.bCheckForHeadShots )
            {
                bIsHeadShot = IsHeadShot(HitLocation, normal(Momentum), 1.0);
        }

      if( bIsHeadShot )
                RemoveHead();

          HitRay = vect(0,0,0);
          if( InstigatedBy != none )
            HitRay = Normal(HitLocation-(InstigatedBy.Location+(vect(0,0,1)*InstigatedBy.EyeHeight)));

      CalcHitLoc( HitLocation, HitRay, HitBone, HitBoneDist );

      if( InstigatedBy != None )
        HitNormal = Normal( Normal(InstigatedBy.Location-HitLocation) + VRand() * 0.2 + vect(0,0,2.8) );
      else
        HitNormal = Normal( Vect(0,0,1) + VRand() * 0.2 + vect(0,0,2.8) );

            // Actually do blood on a client
            PlayHit(Damage, InstigatedBy, hitLocation, damageType, Momentum);

      DoDamageFX( HitBone, Damage, DamageType, Rotator(HitNormal) );
    }

    if ( (DamageType.Default.DamageOverlayMaterial != None) && (Level.DetailMode != DM_Low) && !Level.bDropDetail )
      SetOverlayMaterial(DamageType.Default.DamageOverlayMaterial, DamageType.default.DamageOverlayTime, true);
  }
}


// =============================================================================
defaultproperties
{
  RagdollLifeSpan=120.000000
  Begin Object Class=KarmaParamsSkel Name=KarmaParamsSkel20
    KConvulseSpacing=(Max=2.200000)
    KLinearDamping=0.150000
    KAngularDamping=0.050000
    KBuoyancy=1.000000
    KStartEnabled=True
    KVelDropBelowThreshold=50.000000
    bHighDetailOnly=False
    KFriction=1.300000
    KRestitution=0.200000
    KImpactThreshold=85.000000
  End Object
  KParams=KarmaParamsSkel'INeedBodies.zf_FP.KarmaParamsSkel20'
}