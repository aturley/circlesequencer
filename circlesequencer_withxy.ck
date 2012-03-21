// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; version 2 of the License.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

fun float getInitialStepSize() {
  return 2.0;
}

30::ms => dur gStepDuration;

fun void setStepDuration(dur inStepDuration) {
  inStepDuration => gStepDuration;
}

fun dur getStepDuration() {
  return gStepDuration;
}

class Triggerable {
  fun void trigger() {};
}

class SoundMaker extends Triggerable {
  ADSR mEnv;
  fun void init(UGen out) {
  }
  fun void trigger() {
    mEnv.keyOff();
    mEnv.keyOn();
  }

  fun void adjust(float x, float y) {
  }
}

class BuzzMaker extends SoundMaker {
  SqrOsc mSq;
  fun void adjust(float x, float y) {
    23 + x / 40 => Std.mtof => mSq.freq;
  }
  fun void init(UGen out) {
    mSq => mEnv => out;
    0.1::second => mEnv.attackTime;
    0.1::second => mEnv.decayTime;
    0.0 => mEnv.sustainLevel;
    0.0::second => mEnv.releaseTime;
  }
}

class BeepMaker extends SoundMaker {
  SinOsc mSq;
  fun void adjust(float x, float y) {
    30 + x / 40 => Std.mtof => mSq.freq;
  }
  fun void init(UGen out) {
    mSq => mEnv => out;
    0.1::second => mEnv.attackTime;
    0.1::second => mEnv.decayTime;
    0.0 => mEnv.sustainLevel;
    0.0::second => mEnv.releaseTime;
    700 => mSq.freq;
  }
}

class HissMaker extends SoundMaker {
  fun void init(UGen out) {
    Noise n => mEnv => out;
    0.01::second => mEnv.attackTime;
    0.1::second => mEnv.decayTime;
    0.0 => mEnv.sustainLevel;
    0.0::second => mEnv.releaseTime;
  }
}

class TweetMaker extends SoundMaker {
  SinOsc mS;
  Phasor mP;
  fun void adjust(float x, float y) {
    35 + x / 40 => Std.mtof => mS.freq;
    5 + y / 20 => Std.mtof => mP.freq;
    <<<mS.freq(), mP.freq()>>>;
  }
  fun void init(UGen out) {
    mP => mS => mEnv => out;

    20 => mP.freq;
    50 => mP.gain;

    831 => mS.freq;

    2 => mS.sync;

    0.2::second => mEnv.attackTime;
    0.2::second => mEnv.decayTime;
    0.0 => mEnv.sustainLevel;
    0.0::second => mEnv.releaseTime;
  }
}

class SaySound extends SoundMaker {
  string mSaying;
  fun void trigger() {
    <<< "saying sound:", mSaying >>>;
  }
}

fun SoundMaker soundFactory(string inType) {
  if (inType == "BuzzMaker") {
    BuzzMaker b;
    return b;
  }
  if (inType == "BeepMaker") {
    BeepMaker b;
    return b;
  }
  if (inType == "HissMaker") {
    HissMaker b;
    return b;
  }
  if (inType == "TweetMaker") {
    TweetMaker b;
    return b;
  }
  SaySound s;
  "Sorry, no sound for type '" + inType + "'" => s.mSaying;
  return s;
}

class SaySomething extends Triggerable {
  string mSaying;
  fun void trigger() {
    <<< "saying:", mSaying >>>;
  }
}

class PlaySomething extends Triggerable {
  float freq;
  fun void doit () {
    SqrOsc s => dac;
    freq => s.freq;
    0.2::second => now;
    s =< dac;
  }

  fun void trigger() {
    spork ~ doit();
  }
}

class AngleMarker {
  float mAngle; // (0-2*pi]
  null => SoundMaker @ mSoundMaker;
  fun void doit() {
    if (mSoundMaker != null) {
      mSoundMaker.trigger();
    } else {
      <<< this, "was triggered" >>>;
    }
  }
}

fun int didCrossMarker(CircleSequencer cs, AngleMarker ar, float oldLocation, float newLocation) {
  if (cs.locationToAngle(newLocation) > (2 * pi)) {
    return ((cs.locationToAngle(oldLocation) < (ar.mAngle + (2 * pi))) && (cs.locationToAngle(newLocation) >= (ar.mAngle + (2 * pi))));
  }
  return ((cs.locationToAngle(oldLocation) < ar.mAngle) && (cs.locationToAngle(newLocation) >= ar.mAngle));
}

class CircleSequencer {
  float mX;
  float mY;
  float mRadius;
  0.0 => float mLocation; // current traveled distance from start
  getInitialStepSize() => float mStepSize; // distance traveled in each step

  AngleMarker mAngleMarkerList[0];

  fun void doNextStep() {
    mLocation => float oldLocation;
    mStepSize +=> mLocation;
    getCrossedMarkers(oldLocation, mLocation) @=> AngleMarker crossedMarkers[];
    for (int i; i < crossedMarkers.cap(); i++) {
      crossedMarkers[i].doit();
    }
    if (mLocation >= (2 * mRadius * pi)) {
      mLocation - (2 * mRadius * pi) => mLocation;
    }
  }

  fun AngleMarker[] getCrossedMarkers(float oldLocation, float newLocation) {
    AngleMarker crossedMarkers[0];
    for (int i; i < mAngleMarkerList.cap(); i++) {
      if (didCrossMarker(this, mAngleMarkerList[i], oldLocation, newLocation)) {
	crossedMarkers << mAngleMarkerList[i];
      }
    }
    return crossedMarkers;
  }

  fun float locationToAngle(float location) {
    return location / mRadius;
  }

  fun float angleToLocation(float angle) {
    return mRadius * angle;
  }

  fun float angle() {
    return locationToAngle(mLocation);
  }

  fun void addMarker(AngleMarker am) {
    mAngleMarkerList << am;
    am.mSoundMaker.adjust(mX, mY);
  }

  fun void move(float x, float y) {
    x => mX;
    y => mY;
    for (int i; i < mAngleMarkerList.cap(); i++) {
      mAngleMarkerList[i].mSoundMaker.adjust(x, y);
    }
  }
}

// OSC messages
// /circlesequencer/circle/create,sfff circle_id radius x y
// /circlesequencer/circle/update,sfff circle_id radius x y
// /circlesequencer/marker/add,ssfs circle_id marker_id marker_angle marker_type
// /circlesequencer/marker/update,ssf circle_id marker_id marker_angle

class World {

  OscRecv mOscRecv;
  OscSend mOscViewSend;
  6464 => int kOscRecvPort;
  9191 => int kOscViewSendPort;
  
  OscEvent @ mCircleCreateEvent;
  OscEvent @ mCircleUpdateEvent;

  OscEvent @ mMarkerCreateEvent;
  OscEvent @ mMarkerUpdateEvent;

  OscEvent @ mStepDurationSetEvent;

  CircleSequencer @ mCircleList[0]; // map of "circle id" to circle
  AngleMarker @ mCircleMarkerList[0]; // map of "circle id"+"marker id" to marker

  string mCircleIdList[0]; // list of existing circle ids

  fun void init() {
    initOscRecv();
    initOscViewSend();
  }

  fun void initOscRecv() {
    kOscRecvPort => mOscRecv.port;
    mOscRecv.listen();

    mOscRecv.event("/circlesequencer/circle/create,sfff") @=> mCircleCreateEvent;
    mOscRecv.event("/circlesequencer/circle/update,sfff") @=> mCircleUpdateEvent;

    mOscRecv.event("/circlesequencer/marker/create,ssfs") @=> mMarkerCreateEvent;
    mOscRecv.event("/circlesequencer/marker/update,ssf") @=> mMarkerUpdateEvent;

    mOscRecv.event("/circlesequencer/stepduration/set,f") @=> mStepDurationSetEvent;
  }

  fun void initOscViewSend() {
    mOscViewSend.setHost("127.0.0.1", kOscViewSendPort);
  }

  fun void handleCircleCreate() {
    while (mCircleCreateEvent => now) {
      while (mCircleCreateEvent.nextMsg() != 0) {
	<<<"got circle create message">>>;
	mCircleCreateEvent.getString() => string id;
	mCircleCreateEvent.getFloat() => float radius;
	mCircleCreateEvent.getFloat() => float x;
	mCircleCreateEvent.getFloat() => float y;
	if (mCircleList[id] == null) {
	  CircleSequencer cs;
	  radius => cs.mRadius;
	  x => cs.mX;
	  y => cs.mY;
	  cs @=> mCircleList[id];
	  mCircleIdList << id;
	  mOscViewSend.startMsg("/circlesequencer/circle/create", "sfff");
	  id => mOscViewSend.addString;
	  radius => mOscViewSend.addFloat;
	  x => mOscViewSend.addFloat;
	  y => mOscViewSend.addFloat;
	} else {
	  <<< "circle with id '", id, "' already exists" >>>;
	}
      }
    }
  }

  fun void handleCircleUpdate() {
    while (mCircleUpdateEvent => now) {
      while (mCircleUpdateEvent.nextMsg() != 0) {
	mCircleUpdateEvent.getString() => string id;
	mCircleUpdateEvent.getFloat() => float radius;
	mCircleUpdateEvent.getFloat() => float x;
	mCircleUpdateEvent.getFloat() => float y;
	<<<"got circle update message">>>;
	if (mCircleList[id] != null) {
	  radius => mCircleList[id].mRadius;
	  mCircleList[id].move(x, y);
	  mOscViewSend.startMsg("/circlesequencer/circle/update", "sfff");
	  id => mOscViewSend.addString;
	  radius => mOscViewSend.addFloat;
	  x => mOscViewSend.addFloat;
	  y => mOscViewSend.addFloat;
	} else {
	  <<<"could not update", id, ", no circle with that id">>>;
	}
      }
    }
  }

  fun void handleMarkerCreate() {
    while (mMarkerCreateEvent => now) {
      while (mMarkerCreateEvent.nextMsg() != 0) {
	<<<"got marker create message">>>;
	mMarkerCreateEvent.getString() => string circleId;
	mMarkerCreateEvent.getString() => string markerId;
	mMarkerCreateEvent.getFloat() => float markerAngle;
	mMarkerCreateEvent.getString() => string markerType;

	if (mCircleList[circleId] != null) {
	  AngleMarker am;
	  markerAngle => am.mAngle;
	  soundFactory(markerType) @=> am.mSoundMaker;
	  am.mSoundMaker.init(dac);
	  mCircleList[circleId].addMarker(am);
	  am @=> mCircleMarkerList[circleId + "_" + markerId];
	  mOscViewSend.startMsg("/circlesequencer/marker/create", "ssfs");
	  circleId => mOscViewSend.addString;
	  markerId => mOscViewSend.addString;
	  markerAngle => mOscViewSend.addFloat;
	  markerType => mOscViewSend.addString;
	} else {
	  <<< "circle with id '", circleId, "' does not exists" >>>;
	}
      }
    }
  }

  fun void handleMarkerUpdate() {
    while (mMarkerUpdateEvent => now) {
      while (mMarkerUpdateEvent.nextMsg() != 0) {
	<<<"got marker update message">>>;
	mMarkerUpdateEvent.getString() => string circleId;
	mMarkerUpdateEvent.getString() => string markerId;
	mMarkerUpdateEvent.getFloat() => float markerAngle;

	if (mCircleList[circleId] != null) {
	  if (mCircleMarkerList[circleId + "_" + markerId] != null) {
	    markerAngle => mCircleMarkerList[circleId + "_" + markerId].mAngle;
	    mOscViewSend.startMsg("/circlesequencer/marker/update", "ssf");
	    circleId => mOscViewSend.addString;
	    markerId => mOscViewSend.addString;
	    markerAngle => mOscViewSend.addFloat;
	  } else {
	    <<< "marker with id '", markerId, "' does not exists" >>>;
	  }
	} else {
	  <<< "circle with id '", circleId, "' does not exists" >>>;
	}
      }
    }
  }

  fun void handleStepDurationSet() {
    while (mStepDurationSetEvent => now) {
      while (mStepDurationSetEvent.nextMsg() != 0) {
	<<<"got step duration update message">>>;
	mStepDurationSetEvent.getFloat() => float durFloat;
	setStepDuration(durFloat::ms);
      }
    }
  }
  
  fun void doLoop() {
    do {
      for (int i; i < mCircleIdList.size(); i++) {
	mCircleList[mCircleIdList[i]].doNextStep();
	mOscViewSend.startMsg("/circlesequencer/circle/playangle", "sf");
	mCircleIdList[i] => mOscViewSend.addString;
	mCircleList[mCircleIdList[i]].angle() => mOscViewSend.addFloat;
      }
      getStepDuration() => now;

    } while (true);
  }

  fun void run() {
    spork ~ handleCircleCreate();
    spork ~ handleCircleUpdate();
    spork ~ handleMarkerCreate();
    spork ~ handleMarkerUpdate();
    spork ~ handleStepDurationSet();

    spork ~ doLoop();
  }
}

// ******************************
// Testing.

0 => int testing;

if (testing) {
  soundFactory("BuzzMaker") @=> SoundMaker @ bm;
  bm.init(dac);
  <<< "triggering BuzzMaker" >>>;
  bm.trigger();
  <<< "triggered BuzzMaker" >>>;
  1::second => now;

  soundFactory("BeepMaker") @=> SoundMaker @ bem;
  bem.init(dac);
  <<< "triggering BeepMaker" >>>;
  bem.trigger();
  <<< "triggered BeepMaker" >>>;
  1::second => now;

  soundFactory("HissMaker") @=> SoundMaker @ nm;
  nm.init(dac);
  <<< "triggering HissMaker" >>>;
  nm.trigger();
  <<< "triggered HissMaker" >>>;
  1::second => now;

  me.exit();
 }
// ******************************
// Do it.

World w;

w.init();
w.run();

1::day => now;

me.exit();

