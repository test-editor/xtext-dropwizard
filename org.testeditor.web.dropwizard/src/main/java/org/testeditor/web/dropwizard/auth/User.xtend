package org.testeditor.web.dropwizard.auth

import java.security.Principal
import org.eclipse.xtend.lib.annotations.Data

@Data
class User implements Principal {
	
	String name
	String email	
	
}