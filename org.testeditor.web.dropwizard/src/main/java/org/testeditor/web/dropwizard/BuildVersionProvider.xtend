package org.testeditor.web.dropwizard

import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Paths

class BuildVersionProvider {
		
	var Iterable<String> dependencies
	var Iterable<String> testeditorDependencies
	var String dependencyId 
	
	private def void cacheDependencies(DropwizardApplicationConfiguration configuration, String optionalDependency) {
		val requestedDependencyId = optionalDependency ?: configuration.applicationId
		if (dependencies === null || requestedDependencyId != dependencyId) {
			dependencyId = requestedDependencyId
			val resourceName = '''/«dependencyId».dependencies.txt'''
			val res = class.getResource(resourceName)
			if (res !== null) {
				dependencies = Files.readAllLines(Paths.get(res.toURI), StandardCharsets.UTF_8).filter[!startsWith('#')]
				testeditorDependencies = dependencies.filter[startsWith('org.testeditor')]
			} else {
				dependencies = #[]
				testeditorDependencies = #[]
			}
		}
	}
	
	def Iterable<String> getDependencies(DropwizardApplicationConfiguration configuration, String optionalDependency) {
		cacheDependencies(configuration, optionalDependency)
		return dependencies
	}

	def Iterable<String> getTesteditorDependencies(DropwizardApplicationConfiguration configuration,
		String optionalDependency) {
		cacheDependencies(configuration, optionalDependency)
		return testeditorDependencies
	}
	
}
