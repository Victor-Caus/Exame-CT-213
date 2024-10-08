# Exame CT 213
This is an AI project made for the final test of the subject: Inteligência Artificial para Robótica Móvel – CT-213
In this project, an Neural Network is trained to navigate an agent in 3D space in the Godot game engine(v4.1.1), we used 4 different aproaches to train it:
- Simple Evolution Strategy
- Particle Swarm Optimization
- DQN with simultaneous actions
- DQN with mutually exclusive actions
The biggest challenges of this work was to implement from the learning algorithms scratch. We didn't manage to make the examples with DQN work correctly.

Article: https://drive.google.com/drive/folders/1gM4YKetfbv1SZmB5_iWyULnK7TrMj5fy
## Organization
This project is organized into the following directories and files:
- 'Enviroments': Contains a scene for each aproach (ES, PSO, DQN and DQN2)
- 'external_assets': Contains textures and models used in the project
- 'Optimization_Algorithms': Contains a script for each optimization algorithm (ES, PSO and DQN)
- 'Spaceships(agents)': Contains the scenes and the scripts for the agents that the neural network controls
- 'target_rings': Contains scenes and scripts related to the target rings
- 'exports_presets.cfg': File automatically generated by godot, contains the presets of the exports
- 'NN.gd': Neural network script, for use with ES and PSO
- 'NN_DQN.gd': Neural network script adapted for use with DQN
