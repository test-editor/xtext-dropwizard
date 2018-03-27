package org.testeditor.web.xtext.index.changes

import com.google.common.io.Files
import java.io.File
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.builder.standalone.compiler.IJavaCompiler
import org.eclipse.xtext.builder.standalone.compiler.IJavaCompiler.CompilationResult
import org.eclipse.xtext.common.types.access.impl.IndexedJvmTypeAccess
import org.eclipse.xtext.generator.AbstractFileSystemAccess
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.ChangeDetector
import org.testeditor.web.xtext.index.ChangedResources
import org.testeditor.web.xtext.index.ChunkedResourceDescriptionsProvider
import org.testeditor.web.xtext.index.LanguageAccessRegistry
import org.testeditor.web.xtext.index.buildutils.XtextBuilderUtils

/**
 * Compiles Java sources on the index search path, adds the resulting class
 * files to the class path, and installs a type provider based on a class loader
 * with that class path. 
 * 
 * Based on code extracted from 
 * {@link org.eclipse.xtext.builder.standalone.StandaloneBuilder StandaloneBuilder}.
 */
@Singleton
class CompileJavaBuildStep implements ChangeDetector {

	@Inject IJavaCompiler compiler
	@Inject ChunkedResourceDescriptionsProvider resourceDescriptionsProvider
	@Inject IndexedJvmTypeAccess jvmTypeAccess
	@Inject extension XtextBuilderUtils
	
	File tempDir = Files.createTempDir
	
	static val logger = LoggerFactory.getLogger(CompileJavaBuildStep)
	
	
	override detectChanges(ResourceSet resourceSet, String[] paths, ChangedResources accumulatedChanges) {
		return accumulatedChanges => [
			classPath += compile(classPath, paths)
			resourceDescriptionsProvider.indexResourceSet.installTypeProvider(classPath, jvmTypeAccess)
		]
	}
	
	private def compile(Iterable<String> classPathEntries, Iterable<String> sourceDirs) {
		val buildDir = createTempDir("classes")
		compiler.setClassPath(classPathEntries)
		val sourcesToCompile = uniqueEntries(sourceDirs)
		logger.info("Compiler source roots: " + sourcesToCompile.join(','))
		compiler.compile(sourcesToCompile, buildDir).logCompilerResult

		return buildDir.absolutePath
	}

	private def createTempDir(String subDir) {
		val file = new File(tempDir, subDir)
		if (!file.mkdirs && !file.exists) throw new IOException("Failed to create directory '" + file.absolutePath + "'")
		return file
	}
	
	private def uniqueEntries(Iterable<String> paths) {
		return paths.map[new File(it).absolutePath].toSet
	}
	
	private def logCompilerResult(CompilationResult result) {
		switch (result) {
		case CompilationResult.SKIPPED:
			logger.info("Nothing to compile. Compilation was skipped.")
		case CompilationResult.FAILED:
			logger.info("Compilation finished with errors.")
		case CompilationResult.SUCCEEDED:
			logger.info("Compilation successfully finished.")
		}
	}
	
}
