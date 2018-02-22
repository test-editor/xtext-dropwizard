package org.testeditor.web.dropwizard.xtext.validation

import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.EqualsHashCode
import org.eclipse.xtend.lib.annotations.ToString

@Accessors
@EqualsHashCode
@ToString
class ValidationSummary {

	var String path
	var int errors
	var int warnings
	var int infos

	new() {
	}

	new(String path, int errors, int warnings, int infos) {
		this.path = path
		this.errors = errors
		this.warnings = warnings
		this.infos = infos
	}

	def static ValidationSummary noMarkers(String path) {
		return new ValidationSummary(path, 0, 0, 0)
	}

}
