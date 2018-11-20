object contieneArchivo inherits Exception("La carpeta ya contiene el archivo"){}
object noContieneArchivo inherits Exception("La carpeta no contiene el archivo"){}
object noSePuedeSacarContenido inherits Exception("No se puede sacar ese contenido del final del archivo"){}
object noTienePermisos inherits Exception("El usuario no tiene permiso"){}

class Carpeta{
	var property archivos = []
	var nombre
	
	method contieneArchivo(nombreArchivo){
		return archivos.any({ archivo => archivo.nombre() == nombreArchivo})
	}
	
	method buscarArchivo(nombreArchivo){
		return archivos.find({archivo => archivo.nombre() == nombreArchivo})
	}
	
	method crearArchivo(nombreArchivo){
		archivos.add(new Archivo(nombre=nombreArchivo))
	}

	method eliminarArchivo(nombreArchivo){
		archivos.remove(self.buscarArchivo(nombreArchivo)) 
	}
}

class Archivo{
	var property nombre
	var property contenido = ""
	
	method agregarContenido(agregado){
		contenido += agregado
	}

	method sacarContenido(sacado){
		var posicion = contenido.size() - sacado.size()
		self.validarContenido(sacado, posicion)
		contenido = contenido.take(posicion)
	}

	method validarContenido(sacado, posicion){
		if (sacado != contenido.drop(posicion))
			throw noSePuedeSacarContenido
	}
}

class Commit{
	var descripcion = ""
	var property cambios = []
	var property autor = null
	
	method aplicarEn(carpeta){
		cambios.forEach{cambio => cambio.realizarEn(carpeta)}
	}
	
	method revert(){
		return new Commit(
			descripcion = "Revert "+ descripcion,
			cambios = cambios.map{cambio => cambio.revert()}.reverse())
	}

	method afectaArchivo(nombre){
		return cambios.any{cambio=>cambio.nombreArchivo() == nombre}
	}
}

class Cambio{
	var property nombreArchivo
	            
	method realizarEn(carpeta){
		self.validarRealizacion(carpeta)
		self.realizarse(carpeta) 
	}

	method validarRealizacion(carpeta){
    	if(!carpeta.contieneArchivo(nombreArchivo)) 
    		throw noContieneArchivo
	}

	method realizarse(carpeta) 
}

class Crear inherits Cambio{
	
	override method validarRealizacion(carpeta){
    if(carpeta.contieneArchivo(nombreArchivo)) 
    	throw contieneArchivo
	}

	override method realizarse(carpeta){
		carpeta.crearArchivo(nombreArchivo)
	}
	
	method revert() = new Eliminar(nombreArchivo = nombreArchivo)
}

class Eliminar inherits Cambio{
	
    override method realizarse(carpeta){
    	carpeta.eliminarArchivo(nombreArchivo) 
    }

    method revert() = new Crear(nombreArchivo = nombreArchivo)
}

class Agregar inherits Cambio{
	var agregado
	
    override method realizarse(carpeta){
    	carpeta.buscarArchivo(nombreArchivo).agregarContenido(agregado)
    }
    
    method revert() = new Sacar(nombreArchivo = nombreArchivo, sacado = agregado)
}

class Sacar inherits Cambio{
	var sacado
	    
    override method realizarse(carpeta){
    	carpeta.buscarArchivo(nombreArchivo).sacarContenido(sacado)
    }
    
    method revert() = new Agregar(nombreArchivo = nombreArchivo, agregado = sacado)
}

class Branch{
	var property commits =[]
	var property colaboradores = []
	
	method checkOutEn(carpeta){
		commits.forEach{commit => commit.aplicarEn(carpeta)}
	}
	
	method logDeArchivo(nombre) = commits.filter{commit => commit.afectaArchivo(nombre)}

	method blameDeArchivo(nombre) = self.logDeArchivo(nombre).map{commit => commit.autor()}.asSet()

	method tieneColaborador(usuario) = colaboradores.contains(usuario)
	
	method agregarColaborador(colaborador) {
		colaboradores.add(colaborador)
	}

	method agregarCommit(commit) {
		commits.add(commit)
	}
}

class Usuario{
	var property permiso = comun
	
	method crearBranch(){
		return new Branch(colaboradores = [self])
	}
	
	method agregarColaboradorABranch(colaborador, branch){
		self.validarPermisos(branch)
		branch.agregarColaborador(colaborador)
	}
	
	method commitear(commit, branch){
		self.validarPermisos(branch)
		commit.autor(self)
		branch.agregarCommit(commit)
	}

	method validarPermisos(branch){
		if (!self.tienePermisosEn(branch)) 
			throw noTienePermisos
	} 
	
	method tienePermisosEn(branch){
		return permiso.puedeModificar(self, branch)
	}

	method convertirEnAdministradores(usuarios){
		usuarios.forEach{usuario => permiso.darPermiso(usuario, administrador)}
	}

	method quitarPermisoAdministrador(usuario){
		permiso.darPermiso(usuario,comun)
	}
}

object comun {
	method puedeModificar(usuario, branch) = branch.tieneColaborador(usuario)
	
	method darPermiso(usuario, permiso) {
		throw noTienePermisos
	}
}

object administrador {
	method puedeModificar(usuario, branch) = true

	method darPermiso(usuario, permiso){
		usuario.permiso(permiso)
	}
}
