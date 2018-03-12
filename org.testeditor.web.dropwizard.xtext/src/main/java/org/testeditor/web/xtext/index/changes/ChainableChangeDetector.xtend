package org.testeditor.web.xtext.index.changes

import org.eclipse.emf.ecore.resource.ResourceSet
import org.testeditor.web.xtext.index.ChangeDetector
import org.testeditor.web.xtext.index.ChangedResources
import org.testeditor.web.xtext.index.SetBasedChangedResources

/**
 * Base class for change detectors that can be chained, i.e. run one after the
 * other, and append their results to those previously detected.
 * 
 * This class implements a <it>Chain of Responsibility</it>, as well as a
 * <i>Template Method</i> pattern, which factors out the chaining / successor
 * invocation logic.
 */
abstract class ChainableChangeDetector implements ChangeDetector {
	
	final override ChangedResources detectChanges(ResourceSet resourceSet, String[] paths) {
		return handleAndProceed(resourceSet, paths, new SetBasedChangedResources)
	}
	
	private final def ChangedResources handleAndProceed(ResourceSet resourceSet, String[] paths, SetBasedChangedResources detectedChanges) {
		if (handleChangeDetectionRequest(resourceSet, paths, detectedChanges) && successor !== null) {
			return successor.handleAndProceed(resourceSet, paths, detectedChanges)
		} else {
			return detectedChanges
		}
	}
	
	/**
	 * Handles a change request, potentially based on already detected changes
	 * by change detectors run previously. Detected changes will be appended to
	 * the detectedChanges object.
	 * 
	 * @returns true, if the change detection process should be continued by the
	 * next detector in the chain, or false, if processing should stop.
	 */
	protected def boolean handleChangeDetectionRequest(ResourceSet resourceSet, String[] paths, SetBasedChangedResources detectedChanges)
	
	/**
	 * Returns a change detector that will be run after this one, and on top of
	 * this detector's already detected changes, or null, if this is the last
	 * change detector in the chain. 
	 */
	protected def ChainableChangeDetector getSuccessor()
	
}
