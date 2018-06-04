package org.testeditor.web.xtext.index.changes

import javax.inject.Inject
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.xbase.lib.Functions.Function2
import org.testeditor.web.xtext.index.ChangeDetector
import org.testeditor.web.xtext.index.ChangedResources

import static com.google.common.base.Suppliers.memoize

class TestEditorChangeDetector implements ChangeDetector {

	@Inject GitBasedChangeDetector gitChangeDetector
	@Inject GradleBuildChangeDetector gradleChangeDetector
	@Inject ChangeFilter filter

	var injectorChain = memoize[#[gitChangeDetector, gradleChangeDetector, filter]]

	override detectChanges(ResourceSet resourceSet, String[] paths, ChangedResources accumulatedChanges) {
		return applyInjectorChain(resourceSet, paths, accumulatedChanges) [ detector, changes |
			detector.detectChanges(resourceSet, paths, changes)
		]
	}

	override collectFull(ResourceSet resourceSet, String[] paths, ChangedResources accumulatedChanges) {
		return applyInjectorChain(resourceSet, paths, accumulatedChanges) [ detector, changes |
			detector.collectFull(resourceSet, paths, changes)
		]
	}

	private def ChangedResources applyInjectorChain(ResourceSet resourceSet, String[] paths, ChangedResources accumulatedChanges,
		Function2<ChangeDetector, ChangedResources, ChangedResources> detectionMethod) {
		return injectorChain.get.fold(accumulatedChanges, [ changes, detector |
			return detectionMethod.apply(detector, changes)
		])
	}

}
