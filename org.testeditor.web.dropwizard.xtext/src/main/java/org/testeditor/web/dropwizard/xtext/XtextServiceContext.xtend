package org.testeditor.web.dropwizard.xtext

import java.util.Map
import javax.servlet.http.HttpServletRequest
import javax.ws.rs.core.MultivaluedMap
import org.eclipse.xtext.web.server.IServiceContext
import org.eclipse.xtext.web.servlet.HttpSessionWrapper

class XtextServiceContext implements IServiceContext {

	val HttpServletRequest request
	Map<String, String> parameters = newHashMap
	HttpSessionWrapper sessionWrapper
	
	new(String serviceType, HttpServletRequest request, MultivaluedMap<String, String>... parameters) {
		this.request = request
		this.parameters.put(IServiceContext.SERVICE_TYPE, serviceType)
		for (map : parameters) {
			this.parameters.putAll(map.entrySet.toMap([key], [value.head]))
		}
	}

	override getParameter(String key) {
		return parameters.get(key)
	}

	override getParameterKeys() {
		return parameters.keySet
	}

	override getSession() {
		if (sessionWrapper === null) {
			val session = request.getSession(true)
			sessionWrapper = new HttpSessionWrapper(session)
		}
		return sessionWrapper
	}

}
