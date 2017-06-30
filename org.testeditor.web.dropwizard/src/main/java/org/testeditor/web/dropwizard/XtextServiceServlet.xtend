package org.testeditor.web.dropwizard

import java.util.List
import javax.servlet.ServletException
import javax.servlet.annotation.WebServlet
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.util.DisposableRegistry
import org.eclipse.xtext.web.servlet.XtextServlet

@WebServlet(name='XtextServices', urlPatterns='/xtext-service/*')
class XtextServiceServlet extends XtextServlet {

	@Accessors(PUBLIC_GETTER)
	List<ISetup> languageSetups = newLinkedList

	List<DisposableRegistry> registries = newLinkedList

	override init() throws ServletException {
		super.init()
		for (setup : languageSetups) {
			val injector = setup.createInjectorAndDoEMFRegistration
			registries += injector.getInstance(DisposableRegistry)
		}
	}

	override destroy() {
		registries.forEach[dispose]
		registries.clear
		super.destroy()
	}

}
