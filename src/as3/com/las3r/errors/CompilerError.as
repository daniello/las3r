package com.las3r.errors{

	public class CompilerError extends LispError{

		public function CompilerError(message:String, cause:*){
			super(message, cause);
		}

	}
}