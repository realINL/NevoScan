import image from '../../assets/image2.jpg';       
import InstructionCard from './InstructionCard/InstructionCard';
import './Instruction.css'

const instructions = [
    {
    title: "1. Четкость и фокус",
    instruction: "Объектив камеры должен быть сфокусирован именно на родинке. Фото не должно быть смазанным или размытым "
    },

     {
    title: "2. Хорошее освещение",
    instruction: "Родинка должна быть хорошо освещена, чтобы были видны все детали структуры, границы и цвет. Лучше всего использовать естественный дневной свет"
    },

     {
    title: "3. Отсутствие препятствий",
    instruction: "Родинка должна быть полностью видна. На снимке не должно быть волос, закрывающих родинку, одежды или косметики"
    }
]

const instructionImages = [
    image, image, image
]


function Instruction() {
    return (  
        <div className="instruction load__aside">
            <h1 className='instruction-title'>Рекомендации к фото</h1>
            <div className='instruction-image-grid'>
            { instructionImages.map((src, index) => (
                <img key={index} className='instruction-image' src={src} alt="" />
            ))}
            </div>
            { instructions.map(instruction => (
                <InstructionCard 
                title={instruction.title}
                instruction={instruction.instruction}
                />
            )

            )}
        </div>
    );
}

export default Instruction;