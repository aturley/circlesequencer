import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

HashMap circles;

class Marker {
  private String mType;
  private float mAngle;
  public String getType() {
    return mType;
  }
  public void setType(String inType) {
    mType = inType;
  }
  public float getAngle() {
    return mAngle;
  }
  public void setAngle(float inAngle) {
    mAngle = inAngle;
  }
  public Marker(float inAngle, String inType) {
    mAngle = inAngle;
    mType = inType;
  }
}

class CircleSequencer {
  private float mX;
  private float mY;
  private float mRadius;
  private color mColor;
  
  private float mPlayAngle;
  
  private HashMap mMarkers;
  
  public Collection getMarkers() {
    return mMarkers.values();
  }
  
  public float getX() {
    return mX;
  }
  public float getY() {
    return mY;
  }
  public float getRadius() {
    return mRadius;
  }
  public color getColor() {
    return mColor;
  }
  public float getPlayAngle() {
    return mPlayAngle;
  }
  public void setX(float inX) {
    mX = inX;
  }
  public void setY(float inY) {
    mY = inY;
  }
  public void setRadius(float inRadius) {
    mRadius = inRadius;
  }
  public void setPlayAngle(float inPlayAngle) {
    mPlayAngle = inPlayAngle;
  }
  public void addMarker(String inId, float inAngle, String inType) {
    mMarkers.put(inId, new Marker(inAngle, inType));
  }
  public void updateMarker(String inId, float inAngle) {
    Marker m = (Marker) mMarkers.get(inId);
    m.setAngle(inAngle);
  }
  public CircleSequencer(float inRadius, float inX, float inY, color inColor) {
    mX = inX;
    mY = inY;
    mRadius = inRadius;
    mColor = inColor;
    mMarkers = new HashMap();
    mPlayAngle = 0.0;
  }
}

class CircleSequencerDraw {
  private CircleSequencer mCircleSequencer;
  public CircleSequencerDraw(CircleSequencer inCs) {
    mCircleSequencer = inCs;
  }
  public float getX() {
    return mCircleSequencer.getX() * 2;
  }
  public float getY() {
    return mCircleSequencer.getY() * 2;
  }
  public float getRadius() {
    return mCircleSequencer.getRadius() * 2;
  }
}

void setup() {
  size(450 * 2,250 * 2);
  frameRate(25);
  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this,9191);
  
  circles = new HashMap();
}

int getColorFromMarkerType(Marker m) {
  if (m.getType().equals("HissMaker")) {
    return Color.YELLOW.getRGB();
  } else if (m.getType().equals("BuzzMaker")) {
    // PURPLE
    return 0xFFAF00AF;
  } else if (m.getType().equals("BeepMaker")) {
    return Color.ORANGE.getRGB();
  } else if (m.getType().equals("TweetMaker")) {
    return Color.PINK.getRGB();
  }
  return 0;
}

void draw() {
  background(0);
  ellipseMode(CENTER);
  noFill();
  Collection cs = circles.values();
  for (Iterator i = cs.iterator(); i.hasNext();) {  
    CircleSequencer c = (CircleSequencer) i.next();
    CircleSequencerDraw cd = new CircleSequencerDraw(c);
    stroke(c.getColor());
    ellipse(cd.getX(), cd.getY(), cd.getRadius() * 2, cd.getRadius() * 2);
  }
  noStroke();
  for (Iterator i = cs.iterator(); i.hasNext();) {
    CircleSequencer c = (CircleSequencer) i.next();
    CircleSequencerDraw cd = new CircleSequencerDraw(c);
    Collection ms = c.getMarkers();
    for (Iterator j = ms.iterator(); j.hasNext();) {
      Marker m = (Marker) j.next();
      fill(getColorFromMarkerType(m));      
      ellipse(cd.getX() + cd.getRadius() * cos(m.getAngle()), cd.getY() + cd.getRadius() * sin(m.getAngle()), 10, 10);
    }
    fill(0xFFFFFFFF);
    ellipse(cd.getX() + cd.getRadius() * cos(c.getPlayAngle()), cd.getY() + cd.getRadius() * sin(c.getPlayAngle()), 4, 4);
  }


}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  // print("### received an osc message.");
  // print(" addrpattern: "+theOscMessage.addrPattern());
  // println(" typetag: "+theOscMessage.typetag());
  
  String addrpattern = theOscMessage.addrPattern();
  if (addrpattern.equals("/circlesequencer/circle/create")) {
    println("adding circle");
    String circleId = theOscMessage.get(0).stringValue();
    float radius = theOscMessage.get(1).floatValue();
    float x = theOscMessage.get(2).floatValue();
    float y = theOscMessage.get(3).floatValue();
    CircleSequencer c = new CircleSequencer(radius, x, y, color(0xFF0000FF));
    circles.put(circleId, c);
    println("added circle");
  } else if (addrpattern.equals("/circlesequencer/circle/update")) {
    println("updating circle");
    String circleId = theOscMessage.get(0).stringValue();
    CircleSequencer c = (CircleSequencer) circles.get(circleId);
    float radius = theOscMessage.get(1).floatValue();
    float x = theOscMessage.get(2).floatValue();
    float y = theOscMessage.get(3).floatValue();
    if (c != null) {
      c.setRadius(radius);
      c.setX(x);
      c.setY(y);
    }
    println("updated circle");
  } else if (addrpattern.equals("/circlesequencer/marker/create")) {
    String circleId = theOscMessage.get(0).stringValue();
    CircleSequencer c = (CircleSequencer) circles.get(circleId);
    if (c != null) {
      String markerId = theOscMessage.get(1).stringValue();
      float angle = theOscMessage.get(2).floatValue();
      String type = theOscMessage.get(3).stringValue();
      c.addMarker(markerId, angle, type);
    }
  } else if (addrpattern.equals("/circlesequencer/marker/update")) {
    String circleId = theOscMessage.get(0).stringValue();
    CircleSequencer c = (CircleSequencer) circles.get(circleId);
    if (c != null) {
      String markerId = theOscMessage.get(1).stringValue();
      float angle = theOscMessage.get(2).floatValue();
      c.updateMarker(markerId, angle);
    }
  } else if (addrpattern.equals("/circlesequencer/circle/playangle")) {
    String circleId = theOscMessage.get(0).stringValue();
    CircleSequencer c = (CircleSequencer) circles.get(circleId);
    if (c != null) {
      float angle = theOscMessage.get(1).floatValue();
      c.setPlayAngle(angle);
    }
  }
}
