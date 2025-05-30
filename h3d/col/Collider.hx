package h3d.col;

abstract class Collider {

	/**
		Returns the distance of intersection between the ray and the collider, or negative if no collision.
		If bestMatch is false, only negative/positive value needs to be returned, with no additional precision.
	**/
	public abstract function rayIntersection( r : Ray, bestMatch : Bool ) : Float;
	public abstract function contains( p : Point ) : Bool;
	public abstract function inFrustum( f : Frustum, ?localMatrix : h3d.Matrix ) : Bool;
	public abstract function inSphere( s : Sphere ) : Bool;
	public abstract function dimension() : Float;
	public abstract function closestPoint( p : Point) : Point;

	#if !macro
	public abstract function makeDebugObj() : h3d.scene.Object;
	#end
}


class OptimizedCollider extends Collider {

	public var a : Collider;
	public var b : Collider;
	public var checkInside : Bool;

	public function new(a, b) {
		this.a = a;
		this.b = b;
	}

	public function rayIntersection( r : Ray, bestMatch : Bool ) : Float {
		if( a.rayIntersection(r, false) < 0 ) {
			if( !checkInside )
				return -1;
			if( !a.contains(r.getPoint(0)) )
				return -1;
		}
		return b.rayIntersection(r, bestMatch);
	}

	public function contains( p : Point ) {
		return a.contains(p) && b.contains(p);
	}

	public function inFrustum( f : Frustum, ?m : h3d.Matrix ) {
		return a.inFrustum(f, m) && b.inFrustum(f, m);
	}

	public function inSphere( s : Sphere ) {
		return a.inSphere(s) && b.inSphere(s);
	}

	public function dimension() {
		return Math.max(a.dimension(), b.dimension());
	}

	public function closestPoint( p : h3d.col.Point ) {
		return b.closestPoint(p);
	}

	#if !macro
	public function makeDebugObj() : h3d.scene.Object {
		var bobj = b.makeDebugObj();
		var aobj = a.makeDebugObj();
		if( aobj == null && bobj == null )
			return null;
		var ret = new h3d.scene.Object();
		if( aobj != null )
			ret.addChild(aobj);
		if( bobj != null )
			ret.addChild(bobj);
		return ret;
	}
	#end

}

class GroupCollider extends Collider {

	public var colliders : Array<Collider>;

	public function new(colliders) {
		this.colliders = colliders;
	}

	public function rayIntersection( r : Ray, bestMatch : Bool ) : Float {
		var best = -1.;
		for( c in colliders ) {
			var d = c.rayIntersection(r, bestMatch);
			if( d >= 0 ) {
				if( !bestMatch ) return d;
				if( best < 0 || d < best ) best = d;
			}
		}
		return best;
	}

	public function contains( p : Point ) {
		for( c in colliders )
			if( c.contains(p) )
				return true;
		return false;
	}

	public function inFrustum( f : Frustum, ?m : h3d.Matrix) {
		for( c in colliders )
			if( c.inFrustum(f, m) )
				return true;
		return false;
	}

	public function inSphere( s : Sphere ) {
		for( c in colliders )
			if( c.inSphere(s) )
				return true;
		return false;
	}

	public function dimension() {
		var d = Math.NEGATIVE_INFINITY;
		for ( c in colliders ) {
			d = Math.max(d, c.dimension());
		}
		return d;
	}

	public function closestPoint( p : h3d.col.Point ) {
		var result = null;
		var lengthSq = Math.POSITIVE_INFINITY;
		for ( c in colliders ) {
			var closest = c.closestPoint(p);
			var lSq = closest.distanceSq(p);
			if ( lSq < lengthSq ) {
				result = closest;
				lengthSq = lSq;
			}
		}
		return result;
	}

	#if !macro
	public function makeDebugObj() : h3d.scene.Object {
		var ret : h3d.scene.Object = null;
		for( c in colliders ) {
			var toAdd = c.makeDebugObj();
			if( toAdd == null )
				continue;
			if( ret == null )
				ret = new h3d.scene.Object();
			ret.addChild(toAdd);
		}
		return ret;
	}
	#end


}