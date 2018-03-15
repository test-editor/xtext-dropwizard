package org.testeditor.web.xtext.index.changes

import javax.inject.Inject
import javax.inject.Named
import org.eclipse.emf.ecore.resource.ResourceSet
import org.testeditor.web.xtext.index.SetBasedChangedResources

/**
 * Filters changes detected by preceeding detectors in the chain based on an 
 * {@link IndexFilter IndexFilter}.
 * 
 * Instances of this class are intended to terminate a change detector chain.
 */
class ChangeFilter extends ChainableChangeDetector {
	public static val String FILTER_CHANGES_FOR_INDEX = 'ChangeIndexFilter' 
	
	@Inject @Named(FILTER_CHANGES_FOR_INDEX) extension IndexFilter filter
	
	override protected boolean handleChangeDetectionRequest(ResourceSet resourceSet, String[] paths, SetBasedChangedResources detectedChanges) {
		detectedChanges.modifiedResources.removeIf[!path.isRelevantForIndex]
		detectedChanges.deletedResources.removeIf[!path.isRelevantForIndex]
		return false
	}
	
	override protected getSuccessor() {
		return null
	}
	
}