/**
*   Copyright (c) Rich Hickey. All rights reserved.
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	 the terms of this license.
*   You must not remove this notice, or any other, from this software.
**/

package com.las3r.gen{
	import com.las3r.runtime.*;
	import com.las3r.util.*;
	import com.hurlant.eval.gen.Script;
	import com.hurlant.eval.gen.Method;
	import com.hurlant.eval.gen.ABCEmitter;
	import com.hurlant.eval.gen.AVM2Assembler;
	import com.hurlant.eval.abc.ABCSlotTrait;
	import com.hurlant.eval.abc.ABCException;
	import org.pranaframework.reflection.Type;
	import org.pranaframework.reflection.Field;


	public class SWFGen{

		private var _emitter:ABCEmitter;
		private var _script:Script;
		private var _gen:CodeGen;
		private var _rt:RT;

		public static evalExprOnInit(rt:RT, expr:Expr, callback:Function, errorCallback:Function):SWFGen{
			
			var swf:SWFGen = new SWFGen(rt);
			swf.addInitExpr(expr, callback, errorCallback);
		}

		protected function addInitExpr():void{
			var rt:RT = _rt;
			var gen:CodeGen = _gen;

			var resultKey:String = rt.createResultCallback(callback);
			var errorKey:String = rt.createResultCallback(errorCallback);

			/* Emit bytecode to do the following:
			*
			* - Evaluate 'expr'
			*
			* - Establish a try-catch context around 'expr'
			*   to catch any errors thrown to the top-level
			*
			* - Apply 'callback' to the value of 'expr' or apply
			*   'errorCallback' to the error thrown when evaluating 'expr'
			*/

			gen.pushThisScope();
			gen.pushNewActivationScope();
			gen.cacheRTInstance();

			var tryStart:Object = gen.asm.I_label(undefined);
			expr.emit(C.EXPRESSION, gen);
			gen.callbackWithResult(resultKey);
 			var tryEnd:Object = gen.asm.I_label(undefined);

 			var catchEnd:Object = gen.asm.newLabel();
 			gen.asm.I_jump(catchEnd);

 			var catchStart:Object = gen.asm.I_label(undefined);
 			var excId:int = gen.meth.addException(new ABCException(
 					tryStart.address, 
 					tryEnd.address, 
 					catchStart.address,
 					0, // *
 					gen.emitter.nameFromIdent("toplevelExceptionHandler")
 				));
 			gen.asm.startCatch(); // Increment max stack by 1, for exception object
 			gen.restoreScopeStack(); // Scope stack is wiped on exception, so we reinstate it..
 			gen.pushCatchScope(excId);
 			gen.callbackWithResult(errorKey);
			gen.popScope(); 
			gen.asm.I_returnvoid();
 			gen.asm.I_label(catchEnd);
		}

		public function load():void{
			var file:ABCFile = _emitter.finalize();
			var bytes:ByteArray = file.getBytes();
			bytes.position = 0;
			var swfBytes:ByteArray = ByteLoader.wrapInSWF([bytes]);
			ByteLoader.loadBytes(swfBytes, null, true);
		}


		public function SWFGen(rt:RT){
			_rt = rt;
			_emitter = new ABCEmitter();
			_script = _emitter.newScript();
			_gen = new CodeGen(_rt.instanceId, emitter, scr);
		}
		
	}


}