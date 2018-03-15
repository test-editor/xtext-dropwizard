package org.testeditor.web.xtext.index.buildutils

import java.io.File
import java.io.FileFilter
import java.io.IOException
import java.net.URLClassLoader
import java.util.Set
import java.util.jar.JarFile
import java.util.jar.Manifest
import java.util.zip.ZipException
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.plugin.EcorePlugin
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.common.types.access.impl.ClasspathTypeProvider
import org.eclipse.xtext.mwe.NameBasedFilter
import org.eclipse.xtext.mwe.PathTraverser
import org.eclipse.xtext.resource.XtextResourceSet
import org.slf4j.LoggerFactory

class XtextBuilderUtils {

	static val logger = LoggerFactory.getLogger(XtextBuilderUtils)

	static def Set<URI> collectResources(Iterable<String> roots, ResourceSet resourceSet, Iterable<String> extensions) {
		return collectResources(roots, resourceSet, extensions, null)
	}

	/**
	 * copied and adapted from org.eclipse.xtext.builder.standalone.StandaloneBuilder
	 */
	static def Set<URI> collectResources(Iterable<String> roots, ResourceSet resourceSet, Iterable<String> extensions, FileFilter filter) {
		val nameBasedFilter = new NameBasedFilter

		// TODO test with whitespaced file extensions
		nameBasedFilter.setRegularExpression(".*\\.(?:(" + extensions.join("|") + "))$")
		val resources = <URI>newArrayList

		val pathTraverser = if (filter === null) {
				new PathTraverser
			} else {
				new FilterablePathTraverser(filter)
			}

		val modelsFound = pathTraverser.resolvePathes(
			roots.toList,
			[ input |
				println('''URI: «input.toString»''')
				val matches = nameBasedFilter.matches(input)
				if (matches) {
					resources.add(input)
				}
				return matches
			]
		)
		modelsFound.asMap.forEach [ uri, resource |
			val file = new File(uri)
			if (resource !== null && !file.directory && file.name.endsWith(".jar")) {
				registerBundle(file)
			}
		]
		return resources.toSet
	}

	/**
	 * copied and adapted from org.eclipse.xtext.builder.standalone.StandaloneBuilder
	 */
	static def void registerBundle(File file) {

		// copied from org.eclipse.emf.mwe.utils.StandaloneSetup.registerBundle(File)
		var JarFile jarFile = null
		try {
			jarFile = new JarFile(file)
			val Manifest manifest = jarFile.getManifest
			if (manifest === null)
				return
			var String name = manifest.mainAttributes.getValue("Bundle-SymbolicName")
			if (name !== null) {
				val int indexOf = name.indexOf(';')
				if (indexOf > 0)
					name = name.substring(0, indexOf)
				if (EcorePlugin.platformResourceMap.containsKey(name))
					return
				val String path = "archive:" + file.toURI + "!/"
				val URI uri = URI.createURI(path)
				EcorePlugin.platformResourceMap.put(name, uri)
			}
		} catch (ZipException e) {
			logger.info("Could not open Jar file " + file.getAbsolutePath + ".")
		} catch (Exception e) {
			logger.error(file.absolutePath, e)
		} finally {
			try {
				if (jarFile !== null)
					jarFile.close
			} catch (IOException e) {
				logger.error(jarFile.toString, e)
			}
		}
	}

	/**
	 * copied and adapted from org.eclipse.xtext.builder.standalone.StandaloneBuilder
	 */
	static def void installTypeProvider(XtextResourceSet resourceSet, Iterable<String> classPathRoots) {
		val classLoader = createURLClassLoader(classPathRoots)
		new ClasspathTypeProvider(classLoader, resourceSet, null, null)
		resourceSet.setClasspathURIContext(classLoader)
	}

	/**
	 * copied and adapted from org.eclipse.xtext.builder.standalone.StandaloneBuilder
	 */
	static def private URLClassLoader createURLClassLoader(Iterable<String> classPathEntries) {
		val classPathUrls = classPathEntries.map[str|new File(str).toURI.toURL]
		return new URLClassLoader(classPathUrls)
	}

}
