package org.testeditor.web.dropwizard.xtext.integration

import com.google.inject.Guice
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtext.util.Modules2
import org.eclipse.xtext.web.server.DefaultWebModule
import org.testeditor.web.xtext.index.XtextIndexModule
import org.xtext.example.mydsl.MyDslRuntimeModule
import org.xtext.example.mydsl.MyDslStandaloneSetup
import org.xtext.example.mydsl.ide.MyDslIdeModule

@FinalFieldsConstructor
class MyDslWebModule extends MyDslStandaloneSetup {

	val XtextIndexModule indexModule

	override createInjector() {
		val modules = #[new MyDslRuntimeModule, new MyDslIdeModule, new DefaultWebModule, indexModule]
		val module = Modules2.mixin(modules)
		return Guice.createInjector(module)
	}

}
