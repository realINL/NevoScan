import image from '../../assets/image2.jpg';       
import InstructionCard from './InstructionCard/InstructionCard';
import './Instruction.css'

const instructions = [
    {
    image: image,
    title: "1. Четкость и фокус",
    instruction: "Объектив камеры должен быть сфокуслоова-именно вепоолинке. Фото не лолжно быть смазанным или размытым Если камерэ телефона не может сфокусироваться слишком близко. лучше сфотографировать С небольшого расстояния [10-15 см используя функцию макро или зум"
    },

     {
    image: image,
    title: "2. Хорошее освещение",
    instruction: "Родинка должна быть хорошо освешена. чтобы были вилны все детали структуры, гоаницы и цвет. Лучше всего использовать естественный дневной свет но не прямые солнечные лучи, создающие блики или вспышку телефона. важно избегать темных теней. падающих на новообразование"
    },

     {
    image: image,
    title: "3. Отсутствие препятствий",
    instruction: "Ролинка должна быть полностью видна На снимке не полжно быть вопос закрывающих родинку шпри неооходимости аккуратно сдвинье их или, если родинка на волосистои части головы. лучше не делать снимок самостоятельно бликов от крема. пота или воды. Косметики на родинке"
    }
]


function Instruction() {
    return (  
        <div className='instruction'>
            { instructions.map(instruction => (
                <InstructionCard 
                image={instruction.image}
                title={instruction.title}
                instruction={instruction.instruction}
                />
            )

            )}
        </div>
    );
}

export default Instruction;