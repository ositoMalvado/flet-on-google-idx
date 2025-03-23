{ pkgs, ... }: {
  channel = "stable-23.11";

  packages = [
    pkgs.python3
    pkgs.python3Packages.virtualenv
    pkgs.python3Packages.pip
    pkgs.zrok
    # Añado bash explícitamente para asegurar compatibilidad
    pkgs.bash
  ];

  env = {
    VENV_DIR = ".venv";
    MAIN_FILE = "src/main.py";
    PYTHONPATH = "$PYTHONPATH:$PWD";
  };

  idx = {
    extensions = [
      "ms-python.python"
      "ms-python.debugpy"
      "charliermarsh.ruff"
    ];

    workspace = {
      onCreate = {
        setup-environment = ''
          # Asegurar que los directorios existan
          mkdir -p src
          
          # Crear archivo main.py si no existe
          if [ ! -f "$MAIN_FILE" ]; then
            echo 'import flet as ft

def main(page: ft.Page):
    page.title = "Hello Flet"
    page.add(ft.Text("Hello, World!"))

ft.app(target=main)' > "$MAIN_FILE"
          fi

          # Crear entorno virtual
          python -m venv "$VENV_DIR"
          
          # Activar entorno virtual y verificar que se activó correctamente
          source "$VENV_DIR/bin/activate" || exit 1
          
          # Instalar dependencias
          pip install --upgrade pip
          pip install "flet[all]"
        '';

        default.openFiles = [ "$MAIN_FILE" ];
      };

      onStart = {
        validate-environment = ''
          # Verificar si el entorno virtual existe
          if [ ! -d "$VENV_DIR" ]; then
            echo "Creando entorno virtual nuevo..."
            python -m venv "$VENV_DIR"
          fi
          
          # Activar entorno virtual
          source "$VENV_DIR/bin/activate" || exit 1
          
          # Verificar instalación de flet
          if ! pip show flet > /dev/null; then
            echo "Instalando flet..."
            pip install --upgrade pip
            pip install "flet[all]"
          fi
        '';
      };
    };

    previews = {
      enable = true;
      previews = {
        web = {
          command = [
            "bash" "-c" 
            ''
              # Verificar si el entorno virtual existe
              if [ ! -d "$VENV_DIR" ]; then
                echo "Creando entorno virtual nuevo..."
                python -m venv "$VENV_DIR"
              fi
              
              # Activar entorno virtual
              source "$VENV_DIR/bin/activate" || { echo "Error activando entorno virtual"; exit 1; }
              
              # Verificar instalación de flet
              if ! pip show flet > /dev/null; then
                echo "Instalando flet..."
                pip install --upgrade pip
                pip install "flet[all]"
              fi
              
              # Ejecutar la aplicación
              flet run "$MAIN_FILE" --web --port $PORT
            ''
          ];
          manager = "web";
          onlyWhenOpen = false;
        };
      };
    };
  };
}