//-----------------------------------------------------------
// 
//-----------------------------------------------------------
class INeedBodies extends Mutator;


var() string CG_EndGameBossClass;

// Struct that stores what a specific zombie should be replaced with
struct oldNewZombiePair
{
  var string oldClass;
  var string newClass;
};

// Array that stores all the replacement pairs
var array<oldNewZombiePair> replacementArray;
var array<string> replCaps;


//=============================================================================
function PostBeginPlay()
{
  local int i,k;
  local KFGameType KF;
  local array<string> mcCaps;

  KF = KFGameType(Level.Game);
  if (KF == none)
  {
    log("> INeedBodies: KFGameType not found! Terminating...");
    Destroy();
    return;
  }

  // add ourselves to Package Map!
  AddToPackageMap();

  // fix for invisible zeds after game switches to vanilla / different mods
  if (KF.MonsterCollection == class'KFGameType'.default.MonsterCollection)
  {
    KF.MonsterCollection = class'ZFMonstersCollection';
  }

  for (i = 0; i < KF.MonsterCollection.default.MonsterClasses.Length; i++)
  {
    mcCaps[mcCaps.Length] = Caps(KF.MonsterCollection.default.MonsterClasses[i].MClassName);
  }

  for (i = 0; i < replacementArray.Length; i++)
  {
    replCaps[replCaps.Length] = Caps(replacementArray[i].oldClass);
  }

  // Replace all instances of the old specimens with the new ones 
  for (i = 0; i < mcCaps.Length; i++)
  {
    for (k = 0; k < replCaps.Length; k++)
    {
      if (InStr(mcCaps[i], replCaps[k]) != -1)
      {
        log("> INeedBodies: Replacing" @ KF.MonsterCollection.default.MonsterClasses[i].MClassName @ "with" @ replacementArray[k].newClass);
        KF.MonsterCollection.default.MonsterClasses[i].MClassName = replacementArray[k].newClass;
      }
    }
  }

  // Replace the special squad arrays
  replaceSpecialSquad(KF.MonsterCollection.default.ShortSpecialSquads);
  replaceSpecialSquad(KF.MonsterCollection.default.NormalSpecialSquads);
  replaceSpecialSquad(KF.MonsterCollection.default.LongSpecialSquads);
  replaceSpecialSquad(KF.MonsterCollection.default.FinalSquads);   

  // set the boss class
  KF.MonsterCollection.default.EndGameBossClass = CG_EndGameBossClass;

  // set the fallback zed
  KF.MonsterCollection.default.FallbackMonsterClass = "INeedBodies.zf_Stalker";

  for (i = 0; i < KF.SpecialEventMonsterCollections.Length; i++)
  {
    KF.SpecialEventMonsterCollections[i] = KF.MonsterCollection;
  }
}


// Replaces the zombies in the given squadArray
final function replaceSpecialSquad(out array<KFMonstersCollection.SpecialSquad> squadArray)
{
  local int i,j,k;

  for (j=0; j<squadArray.Length; j++)
  {
    for (i=0; i<squadArray[j].ZedClass.Length; i++)
    {
      for (k=0; k<replacementArray.Length; k++)
      {
        if (InStr(Caps(squadArray[j].ZedClass[i]), replCaps[k]) != -1)
        {
          squadArray[j].ZedClass[i] = replacementArray[k].newClass;
        }
      }
    }
  }
}


//=============================================================================
defaultproperties
{
  GroupName="KF-MonsterMut"
  FriendlyName="Forever Dead Scums!"
  Description="Long lasting kills!"
  CG_EndGameBossClass="KFChar.ZombieBoss_STANDARD"
  replacementArray(0)=(oldClass="KFChar.ZombieFleshPound",newClass="INeedBodies.zf_FP")
  replacementArray(1)=(oldClass="KFChar.ZombieGorefast",newClass="INeedBodies.zf_Gorefast")
  replacementArray(2)=(oldClass="KFChar.ZombieStalker",newClass="INeedBodies.zf_Stalker")
  replacementArray(3)=(oldClass="KFChar.ZombieSiren",newClass="INeedBodies.zf_Siren")
  replacementArray(4)=(oldClass="KFChar.ZombieScrake",newClass="INeedBodies.zf_SC")
  replacementArray(5)=(oldClass="KFChar.ZombieHusk",newClass="INeedBodies.zf_Husk")
  replacementArray(6)=(oldClass="KFChar.ZombieCrawler",newClass="INeedBodies.zf_Crawler")
  replacementArray(7)=(oldClass="KFChar.ZombieBloat",newClass="INeedBodies.zf_Bloat")
  replacementArray(8)=(oldClass="KFChar.ZombieClot",newClass="INeedBodies.zf_Clot")
}