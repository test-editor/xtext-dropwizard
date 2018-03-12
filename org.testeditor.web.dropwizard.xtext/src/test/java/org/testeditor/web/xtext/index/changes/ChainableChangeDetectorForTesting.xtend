package org.testeditor.web.xtext.index.changes

import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.testeditor.web.xtext.index.SetBasedChangedResources

@FinalFieldsConstructor
class ChainableChangeDetectorForTesting extends ChainableChangeDetector {

	val (SetBasedChangedResources)=>boolean handleResult
	val ChainableChangeDetector successor

	override handleChangeDetectionRequest(ResourceSet resourceSet, String[] paths, SetBasedChangedResources detectedChanges) {
		return this.handleResult.apply(detectedChanges)
	}

	override protected getSuccessor() {
		return this.successor
	}

}
