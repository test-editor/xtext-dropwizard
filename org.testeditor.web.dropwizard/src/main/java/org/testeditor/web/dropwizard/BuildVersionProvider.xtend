package org.testeditor.web.dropwizard

import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Paths

class BuildVersionProvider {
		
	var Iterable<String> dependencies
	var Iterable<String> testeditorDependencies
	var String dependencyId 
	
	private def void cacheDependencies(DropwizardApplicationConfiguration configuration, String optionalDependency) {
		if (dependencies === null || configuration.applicationId != dependencyId) {
			dependencyId = optionalDependency?:configuration.applicationId
			val resourceName = '''/«dependencyId».dependencies.txt'''
			val res = class.getResource(resourceName)
			dependencies = Files.readAllLines(Paths.get(res.toURI), StandardCharsets.UTF_8).filter[!startsWith('#')]
			testeditorDependencies = dependencies.filter[startsWith('org.testeditor')]
		}
	}
	
	def Iterable<String> getDependencies(DropwizardApplicationConfiguration configuration, String optionalDependency) {
		cacheDependencies(configuration, optionalDependency)
		return dependencies
	}
	
	def Iterable<String> getTesteditorDependencies(DropwizardApplicationConfiguration configuration, String optionalDependency) {
		cacheDependencies(configuration, optionalDependency)
		return testeditorDependencies
	}
	
}
